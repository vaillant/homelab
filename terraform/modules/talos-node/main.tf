terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos_node" {
  name        = var.vm_name
  node_name   = var.target_node
  description = "Talos Kubernetes node managed by Terraform"

  # Use UEFI boot
  bios    = "ovmf"
  machine = "q35"

  # EFI disk
  efi_disk {
    datastore_id = var.disk_storage
    type         = "4m"
  }

  # VM settings
  on_boot = true
  started = true

  # CPU
  cpu {
    cores   = var.cores
    sockets = 1
    type    = "host"
  }

  # Memory
  memory {
    dedicated = var.memory
  }

  # QEMU guest agent
  agent {
    enabled = true
  }

  # Boot from ISO first, then disk
  boot_order = ["ide2", "scsi0"]

  # Operating system
  operating_system {
    type = "l26"
  }

  # CD-ROM with Talos ISO
  cdrom {
    enabled   = true
    file_id   = var.talos_iso_id
    interface = "ide2"
  }

  # Main disk - empty, Talos will install here
  disk {
    interface    = "scsi0"
    datastore_id = var.disk_storage
    size         = var.disk_size
    discard      = "on"
    ssd          = true
  }

  # SCSI controller
  scsi_hardware = "virtio-scsi-single"

  # Network
  network_device {
    model  = "virtio"
    bridge = var.bridge
  }

}
