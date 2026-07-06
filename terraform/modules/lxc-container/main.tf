resource "proxmox_lxc" "container" {
  hostname    = var.hostname
  target_node = var.target_node
  ostemplate  = var.ostemplate
  description = var.description

  # Container settings
  cores      = var.cores
  memory     = var.memory
  swap       = var.swap
  onboot     = var.onboot
  start      = var.start
  unprivileged = var.unprivileged

  # Root filesystem
  rootfs {
    storage = var.rootfs_storage
    size    = var.rootfs_size
  }

  # Network
  dynamic "network" {
    for_each = var.networks
    content {
      name   = network.value.name
      bridge = network.value.bridge
      ip     = lookup(network.value, "ip", "dhcp")
      gw     = lookup(network.value, "gw", null)
      tag    = lookup(network.value, "tag", null)
    }
  }

  # Additional mount points
  dynamic "mountpoint" {
    for_each = var.mountpoints
    content {
      key     = mountpoint.key
      slot    = mountpoint.key
      storage = mountpoint.value.storage
      size    = mountpoint.value.size
      mp      = mountpoint.value.mp
    }
  }

  # SSH public key
  ssh_public_keys = var.ssh_keys != "" ? var.ssh_keys : null

  # Password
  password = var.password

  # Features
  features {
    nesting = var.features_nesting
    fuse    = var.features_fuse
  }

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}
