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

  # Clone from NixOS template. When the template lives on a different node,
  # set template_node so bpg performs a cross-node (full) clone.
  clone {
    vm_id     = var.template_id
    node_name = var.template_node != "" ? var.template_node : null
    full      = var.template_node != "" ? true : null
  }

  # CPU. Default to "host" so the guest gets the host's full instruction set
  # (SSE4.2/AVX/...). The bpg default (kvm64 / "QEMU Virtual CPU") lacks these,
  # which makes modern bundled JS/WASM tools (e.g. claude-code) busy-loop at
  # 100% CPU on startup.
  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = var.cpu_type
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
    type = "l26" # Linux kernel 2.6+
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
    # Where Proxmox stores the generated cloud-init (cidata) drive.
    datastore_id = var.ci_datastore_id

    ip_config {
      ipv4 {
        address = var.ipconfig0
      }
    }

    # Only emit a cloud-init user when ci_user is set. NixOS VMs create their
    # admin user declaratively (see nix/vm/base.nix), so they leave this empty.
    dynamic "user_account" {
      for_each = var.ci_user != "" ? [1] : []
      content {
        username = var.ci_user
        password = var.ci_password
        keys     = var.ssh_keys != "" ? split("\n", var.ssh_keys) : []
      }
    }
  }

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network_device,
    ]
  }
}
