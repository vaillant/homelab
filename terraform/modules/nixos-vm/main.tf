terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.0"
    }
  }
}

resource "proxmox_vm_qemu" "nixos_vm" {
  name        = var.vm_name
  target_node = var.target_node
  desc        = var.description

  # Clone from NixOS template
  clone = var.template_name

  # VM Settings
  agent    = 1
  cores    = var.cores
  sockets  = var.sockets
  memory   = var.memory
  balloon  = var.balloon
  onboot   = var.onboot
  startup  = var.startup

  # Boot settings
  boot     = "order=scsi0"
  scsihw   = "virtio-scsi-single"

  # Enable QEMU guest agent
  qemu_os = "l26"  # Linux kernel 2.6+

  # Network
  dynamic "network" {
    for_each = var.networks
    content {
      model  = network.value.model
      bridge = network.value.bridge
      tag    = lookup(network.value, "tag", null)
    }
  }

  # Disk
  dynamic "disk" {
    for_each = var.disks
    content {
      type    = disk.value.type
      storage = disk.value.storage
      size    = disk.value.size
      format  = lookup(disk.value, "format", "raw")
      ssd     = lookup(disk.value, "ssd", 1)
      discard = lookup(disk.value, "discard", "on")
    }
  }

  # Cloud-init configuration
  os_type   = "cloud-init"
  ipconfig0 = var.ipconfig0

  ciuser     = var.ci_user
  cipassword = var.ci_password
  sshkeys    = var.ssh_keys

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}
