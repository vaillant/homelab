# NixOS builder environment
# Manages the nix-builder VM for building NixOS images

# Cloud-init user data
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.storage
  node_name    = var.target_node

  source_raw {
    data = <<-EOF
      #cloud-config
      users:
        - name: root
          lock_passwd: false
          ssh_authorized_keys:
            - ${var.ssh_pubkey}
        - name: ubuntu
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          ssh_authorized_keys:
            - ${var.ssh_pubkey}
      ssh_pwauth: false
      package_update: true
      packages:
        - qemu-guest-agent
      runcmd:
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
    EOF

    file_name = "nix-builder-cloud-init.yaml"
  }
}

# Download Ubuntu cloud image
resource "proxmox_download_file" "ubuntu_image" {
  content_type        = "iso"
  datastore_id        = var.storage
  node_name           = var.target_node
  file_name           = "ubuntu-24.04-server-cloudimg-amd64.img"
  overwrite_unmanaged = true

  url = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
}

# Create the NixOS builder VM
resource "proxmox_virtual_environment_vm" "nix_builder" {
  name        = "nix-builder"
  node_name   = var.target_node
  description = "NixOS remote builder"

  # Use UEFI boot
  bios = "ovmf"
  machine = "q35"

  # EFI disk for UEFI boot
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

  # Enable QEMU guest agent
  agent {
    enabled = true
  }

  # Boot from disk
  boot_order = ["scsi0"]

  # Operating system type
  operating_system {
    type = "l26"
  }

  # Main disk - import from downloaded image
  disk {
    interface    = "scsi0"
    datastore_id = var.disk_storage
    size         = var.disk_size
    file_id      = proxmox_download_file.ubuntu_image.id
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

  # Cloud-init configuration
  initialization {
    datastore_id      = var.disk_storage
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.gateway
      }
    }
  }

  lifecycle {
    ignore_changes = [
      disk[0].file_id,
    ]
  }
}
