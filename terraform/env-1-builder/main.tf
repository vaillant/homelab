# NixOS builder environment
# Manages the nix-builder VM for building NixOS images

# Cloud-init user data to install QEMU guest agent
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.storage
  node_name    = var.target_node

  source_raw {
    data = <<-EOF
      #cloud-config
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

# Download Debian cloud image
resource "proxmox_download_file" "debian_image" {
  content_type = "iso"
  datastore_id = var.storage
  node_name    = var.target_node
  file_name    = "debian-12-generic-amd64.img"

  url = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
}

# Create the NixOS builder VM
resource "proxmox_virtual_environment_vm" "nix_builder" {
  name        = "nix-builder"
  node_name   = var.target_node
  description = "NixOS remote builder"

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
    file_id      = proxmox_download_file.debian_image.id
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

    user_account {
      username = "root"
      keys     = [var.ssh_pubkey]
    }
  }

  lifecycle {
    ignore_changes = [
      disk[0].file_id,
    ]
  }
}
