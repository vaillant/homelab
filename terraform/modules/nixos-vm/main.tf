terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_vm" "nixos_vm" {
  name        = var.vm_name
  node_name   = var.target_node
  description = var.description

  # Clone from NixOS template
  clone {
    vm_id = var.template_id
  }

  # CPU
  cpu {
    cores   = var.cores
    sockets = var.sockets
  }

  # Memory
  memory {
    dedicated = var.memory
    floating  = var.balloon
  }

  # Boot settings
  on_boot = var.onboot
  started = true

  # Enable QEMU guest agent
  agent {
    enabled = true
  }

  # Operating system
  operating_system {
    type = "l26"  # Linux kernel 2.6+
  }

  # Network
  dynamic "network_device" {
    for_each = var.networks
    content {
      model   = network_device.value.model
      bridge  = network_device.value.bridge
      vlan_id = lookup(network_device.value, "tag", null)
    }
  }

  # Disk
  dynamic "disk" {
    for_each = var.disks
    content {
      interface    = "${disk.value.type}${disk.key}"
      datastore_id = disk.value.storage
      size         = tonumber(regex("^(\\d+)", disk.value.size)[0])
      file_format  = lookup(disk.value, "format", "raw")
      discard      = lookup(disk.value, "discard", "on")
      ssd          = lookup(disk.value, "ssd", 0) == 1 ? true : false
    }
  }

  # Cloud-init configuration
  initialization {
    ip_config {
      ipv4 {
        address = var.ipconfig0
      }
    }

    user_account {
      username = var.ci_user
      password = var.ci_password
      keys     = var.ssh_keys != "" ? split("\n", var.ssh_keys) : []
    }
  }

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}
