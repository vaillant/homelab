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
      backup = mount_point.value.backup
    }
  }

  # Host device passthrough (e.g. /dev/dri/renderD128 for GPU hardware transcode)
  dynamic "device_passthrough" {
    for_each = coalesce(var.device_passthrough, [])
    content {
      path = device_passthrough.value.path
      mode = device_passthrough.value.mode
      gid  = device_passthrough.value.gid
      uid  = device_passthrough.value.uid
    }
  }

  # Features (only nesting can be changed by non-root API tokens)
  features {
    nesting = var.features_nesting
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
