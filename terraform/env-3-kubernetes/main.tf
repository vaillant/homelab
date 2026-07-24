# Talos Kubernetes Cluster
# HA cluster with all nodes as control plane + worker

# Discover available Proxmox nodes
data "proxmox_virtual_environment_nodes" "available" {}

locals {
  # Get list of available PVE nodes
  pve_nodes = data.proxmox_virtual_environment_nodes.available.names

  # Actual node count: min(requested, available PVE nodes)
  # If cluster has 1 node → 1 Talos VM; if 3 nodes → up to node_count VMs
  actual_node_count = min(var.node_count, length(local.pve_nodes))

  # Parse IP base into prefix and last octet for arithmetic
  # ip_base="192.168.0.20" → prefix="192.168.0", base_octet=20
  ip_parts   = split(".", var.ip_base)
  ip_prefix  = join(".", slice(local.ip_parts, 0, 3))
  base_octet = tonumber(local.ip_parts[3])

  # Generate node map from count and IP base
  # ip_base="192.168.0.20" + count=3 → .21, .22, .23
  nodes = { for i in range(local.actual_node_count) :
    "talos-${i + 1}" => {
      target_node = local.pve_nodes[i % length(local.pve_nodes)]
      ip_address  = "${local.ip_prefix}.${local.base_octet + i + 1}"
      gateway     = var.gateway
      cores       = var.node_cores
      memory      = var.node_memory
      disk_size   = var.node_disk
    }
  }

  # Cluster endpoint is the first node IP
  cluster_endpoint = "https://${local.nodes["talos-1"].ip_address}:6443"
}

# Download Talos ISO from Image Factory (ISO doesn't need decompression)
resource "proxmox_download_file" "talos_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = local.pve_nodes[0]
  file_name    = "talos-${var.talos_version}-nocloud-amd64.iso"
  url          = replace(var.talos_image_url, ".raw.xz", ".iso")
}

# Generate Talos machine secrets (cluster-wide)
resource "talos_machine_secrets" "this" {}

# Generate client configuration for talosctl
data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for node in local.nodes : node.ip_address]
  nodes                = [for node in local.nodes : node.ip_address]
}

# Generate machine configuration for each node
data "talos_machine_configuration" "nodes" {
  for_each = local.nodes

  cluster_name     = var.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  talos_version    = var.talos_version

  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/sda"
        }
        network = {
          hostname = each.key
          interfaces = [{
            interface = "eth0"
            addresses = ["${each.value.ip_address}/24"]
            routes = [{
              network = "0.0.0.0/0"
              gateway = each.value.gateway
            }]
          }]
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
      }
    })
  ]
}

# Create Talos VMs
module "talos_nodes" {
  source   = "../modules/talos-node"
  for_each = local.nodes

  vm_name      = each.key
  target_node  = each.value.target_node
  disk_storage = var.default_storage
  bridge       = var.default_bridge

  cores     = each.value.cores
  memory    = each.value.memory
  disk_size = each.value.disk_size

  talos_iso_id = proxmox_download_file.talos_image.id
}

# Apply machine configuration to each node
resource "talos_machine_configuration_apply" "nodes" {
  for_each = local.nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.nodes[each.key].machine_configuration
  node                        = each.value.ip_address

  depends_on = [module.talos_nodes]
}

# Bootstrap the cluster (only on first control plane node)
resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.nodes["talos-1"].ip_address

  depends_on = [talos_machine_configuration_apply.nodes]
}

# Wait for cluster health
data "talos_cluster_health" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  control_plane_nodes  = [for node in local.nodes : node.ip_address]
  endpoints            = [for node in local.nodes : node.ip_address]

  depends_on = [talos_machine_bootstrap.this]
}

# Retrieve kubeconfig (using resource instead of deprecated data source)
resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.nodes["talos-1"].ip_address

  depends_on = [data.talos_cluster_health.this]
}
