# Kubernetes on Talos Linux with Cilium CNI (Proxmox)
#
# Uses the community module github.com/alexmorbo/terraform-proxmox-talos,
# adapted from its "Quick Start" example to this homelab. The module builds
# the Talos node VMs on Proxmox, registers the image schematic with the
# Talos Image Factory, bootstraps the cluster, and installs Cilium
# (kube-proxy replacement) as the CNI.
#
# Nodes use DHCP for their primary address (like the upstream example); the
# Kubernetes API is reached through the static `cluster_vip`. The Proxmox and
# Talos providers authenticate via the same environment variables used by the
# other environments (exported by the root Taskfile):
#   PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN, PROXMOX_VE_SSH_PRIVATE_KEY

locals {
  # ---- Cluster configuration (edit these) ---------------------------------
  cluster_name       = "homelab"
  talos_cp_version   = "1.13.7" # no 'v' prefix; module (master) needs Talos >= 1.12 for the HostnameConfig doc
  kubernetes_version = "1.33.0"
  # iscsi-tools + util-linux-tools are required by Longhorn on Talos.
  talos_schematic = [
    "siderolabs/qemu-guest-agent",
    "siderolabs/iscsi-tools",
    "siderolabs/util-linux-tools",
  ]

  # Proxmox placement
  proxmox_cluster_name = "homelab"
  proxmox_nodes        = ["proxmox1", "proxmox-pc-2", "proxmox-pc-3"]
  default_storage      = "local-zfs" # datastore for VM disks
  image_storage        = "local"     # datastore for downloaded Talos images
  default_bridge       = "vmbr0"

  # Networking
  default_gateway = "192.168.0.1"
  cluster_vip     = "192.168.0.30" # must be free and inside vm_subnet
  vm_subnet       = "192.168.0.0/24"
  pod_subnet      = "10.209.0.0/16" # cluster-internal
  service_subnet  = "10.208.0.0/16" # cluster-internal

  # Static node addressing: control planes take .31, .32, .33 (one per
  # Proxmox node) and workers continue from there (.34, .35, ...).
  ip_start = 31

  # Sizing
  controlplane_cpu = 4
  controlplane_ram = 4096
  worker_count     = 2 # set to 0 to run workloads on control planes only
  worker_cpu       = 2
  worker_ram       = 4096

  # Default route for the static-IP nodes (the module adds no gateway route
  # on its own — without this, nodes cannot reach the internet/registries).
  static_routes = [{
    network = "0.0.0.0/0"
    gateway = local.default_gateway
  }]

  # Dedicated per-node data disk for Longhorn (local-zfs backed), surfaced in
  # the guest as /dev/vdb (virtio1).
  data_disk_size = 100

  # Talos machine-config patches (via the forked module's machine_config_patches
  # escape hatch): format the data disk and mount it at Longhorn's data path,
  # and bind-mount that path into the kubelet mount namespace with rshared
  # propagation (both required by Longhorn on Talos).
  machine_config_patches = [
    yamlencode({
      machine = {
        disks = [{
          device     = "/dev/vdb"
          partitions = [{ mountpoint = "/var/lib/longhorn" }]
        }]
        kubelet = {
          extraMounts = [{
            destination = "/var/lib/longhorn"
            type        = "bind"
            source      = "/var/lib/longhorn"
            options     = ["bind", "rshared", "rw"]
          }]
        }
      }
    })
  ]

  # ---- Derived topology ---------------------------------------------------
  # Static IPs require count = 1 per group: the module copies a group's
  # single `address` to every VM in it, so one VM per group avoids clashes.

  # One control-plane VM per Proxmox node (.31, .32, .33) → HA control plane.
  controlplanes = {
    for idx, node in local.proxmox_nodes : node => {
      count = 1
      cpu   = local.controlplane_cpu
      ram   = local.controlplane_ram
      networks = [{
        interface     = "eth0"
        bridge        = local.default_bridge
        address       = cidrhost(local.vm_subnet, local.ip_start + idx)
        dhcp_disabled = true
      }]
    }
  }

  # One worker per Proxmox node, all in the "default" pool, each with a
  # distinct static IP continuing after the control planes (.34, .35, ...).
  # Static IPs require count = 1 per group, and the group MUST be named
  # "default" — the module taints any other group name as a dedicated pool
  # (register-with-taints node.home.lab/dedicated). This caps worker_count
  # at the number of Proxmox nodes.
  workers = {
    for i in range(local.worker_count) : local.proxmox_nodes[i] => {
      default = {
        count = 1
        cpu   = local.worker_cpu
        ram   = local.worker_ram
        networks = [{
          interface     = "eth0"
          bridge        = local.default_bridge
          address       = cidrhost(local.vm_subnet, local.ip_start + length(local.proxmox_nodes) + i)
          dhcp_disabled = true
        }]
      }
    }
  }
}

module "talos_cluster" {
  # Fork of alexmorbo/terraform-proxmox-talos that adds `machine_config_patches`
  # + `data_disk_size` (branch machine-config-patches).
  source = "github.com/vaillant/terraform-proxmox-talos-module?ref=machine-config-patches"

  cluster_name       = local.cluster_name
  talos_cp_version   = local.talos_cp_version
  kubernetes_version = local.kubernetes_version
  talos_schematic    = local.talos_schematic

  default_gateway = local.default_gateway
  cluster_vip     = local.cluster_vip

  vm_subnet      = local.vm_subnet
  pod_subnet     = local.pod_subnet
  service_subnet = local.service_subnet

  proxmox_cluster = {
    cluster_name = local.proxmox_cluster_name
    nodes = {
      for node in local.proxmox_nodes : node => {
        datastore     = local.default_storage
        iso_datastore = local.image_storage
      }
    }
  }

  controlplanes = local.controlplanes
  workers       = local.workers
  static_routes = local.static_routes

  data_disk_size         = local.data_disk_size
  machine_config_patches = local.machine_config_patches

  # Cilium is installed by the module with sensible defaults
  # (kube-proxy replacement, Hubble). Override via `cilium_values` if needed.
}
