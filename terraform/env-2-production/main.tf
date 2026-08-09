# Production environment
# Manages NixOS VMs and LXC containers

# NixOS VMs
module "nixos_vms" {
  source   = "../modules/nixos-vm"
  for_each = var.nixos_vms

  # Note: coalesce/ternary (not lookup defaults) because optional object
  # attributes are present-but-null when omitted, so lookup never falls back.
  vm_name     = each.key
  target_node = each.value.target_node
  description = coalesce(each.value.description, "NixOS VM managed by Terraform")
  template_id = var.nixos_template_id

  # Cross-node clone when the VM's node differs from the template's node.
  template_node = each.value.target_node != var.nixos_template_node ? var.nixos_template_node : ""

  # Resources
  cores   = coalesce(each.value.cores, 2)
  sockets = coalesce(each.value.sockets, 1)
  memory  = coalesce(each.value.memory, 2048)
  balloon = coalesce(each.value.balloon, 1024)

  # Boot settings
  onboot  = coalesce(each.value.onboot, true)
  startup = each.value.startup != null ? each.value.startup : ""

  # Network
  networks = each.value.networks != null ? each.value.networks : [{
    model  = "virtio"
    bridge = var.default_bridge
  }]

  # Disks
  disks = each.value.disks != null ? each.value.disks : [{
    type    = "scsi"
    storage = var.default_storage
    size    = "32G"
    ssd     = 1
    discard = "on"
  }]

  # Cloud-init
  ipconfig0       = coalesce(each.value.ipconfig0, "dhcp")
  ci_user         = coalesce(each.value.ci_user, "root")
  ci_datastore_id = var.default_storage
  ssh_keys        = var.ssh_public_keys
}

# LXC containers
module "lxc_containers" {
  source   = "../modules/lxc-container"
  for_each = var.lxc_containers

  hostname    = each.key
  target_node = each.value.target_node
  ostemplate  = coalesce(each.value.ostemplate, var.default_lxc_template)
  description = lookup(each.value, "description", "LXC container managed by Terraform")

  # Resources
  cores  = lookup(each.value, "cores", 1)
  memory = lookup(each.value, "memory", 512)
  swap   = lookup(each.value, "swap", 512)

  # Boot settings
  onboot = coalesce(each.value.onboot, true)
  start  = coalesce(each.value.start, true)

  # Security
  unprivileged = coalesce(each.value.unprivileged, true)

  # Storage
  rootfs_storage = lookup(each.value, "rootfs_storage", var.default_storage)
  rootfs_size    = lookup(each.value, "rootfs_size", "8G")

  # Network
  networks = lookup(each.value, "networks", [{
    name   = "eth0"
    bridge = var.default_bridge
    ip     = "dhcp"
  }])

  # Additional mount points
  mountpoints = lookup(each.value, "mountpoints", {})

  # Access
  ssh_keys = var.ssh_public_keys

  # Features
  features_nesting = lookup(each.value, "features_nesting", true)
  features_fuse    = lookup(each.value, "features_fuse", false)
}
