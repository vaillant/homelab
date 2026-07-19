terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_container" "container" {
  node_name   = var.target_node
  description = var.description

  # Operating system template
  operating_system {
    template_file_id = var.ostemplate
    type             = "nixos"
  }

  # Initialization
  initialization {
    hostname = var.hostname

    dynamic "ip_config" {
      for_each = var.networks
      content {
        ipv4 {
          address = lookup(ip_config.value, "ip", null) == "dhcp" ? "dhcp" : lookup(ip_config.value, "ip", "dhcp")
          gateway = lookup(ip_config.value, "gw", null)
        }
      }
    }
  }

  # CPU
  cpu {
    cores = var.cores
  }

  # Memory
  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  # Root filesystem
  disk {
    datastore_id = coalesce(var.rootfs_storage, "local-zfs")
    size         = tonumber(regex("^(\\d+)", coalesce(var.rootfs_size, "8G"))[0])
  }

  # Network interfaces
  dynamic "network_interface" {
    for_each = var.networks
    content {
      name    = network_interface.value.name
      bridge  = network_interface.value.bridge
      vlan_id = lookup(network_interface.value, "tag", null)
    }
  }

  # Additional mount points
  dynamic "mount_point" {
    for_each = coalesce(var.mountpoints, {})
    content {
      volume = "${mount_point.value.storage}:${tonumber(regex("^(\\d+)", mount_point.value.size)[0])}"
      path   = mount_point.value.mp
    }
  }

  # Features
  features {
    nesting = var.features_nesting
    fuse    = var.features_fuse
  }

  # Startup
  unprivileged  = var.unprivileged
  start_on_boot = var.onboot
  started       = var.start

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network_interface,
    ]
  }
}
