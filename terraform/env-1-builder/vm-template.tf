# Phase 2 (VM variant): NixOS VM template.
#
# The `vm-build` task builds a qcow2 on the nix-builder, uploads it to Proxmox
# and writes `vm_image_file` into vm-image.auto.tfvars. This resource then
# imports that disk and turns it into a cloud-init-ready template (VM 9000),
# which env-2-production clones via modules/nixos-vm.
#
# Guarded by count so it only exists once an image has been built.

# disk.import_from only takes effect at create time (bpg ignores changes to it
# on an existing VM). Track the image id here so a new build forces the template
# to be replaced, actually re-importing the fresh qcow2.
resource "terraform_data" "vm_image_version" {
  input = var.vm_image_file
}

resource "proxmox_virtual_environment_vm" "nixos_template" {
  count = var.vm_image_file != "" ? 1 : 0

  lifecycle {
    replace_triggered_by = [terraform_data.vm_image_version]
  }

  vm_id       = var.nixos_template_id
  name        = "nixos-template"
  node_name   = var.target_node
  description = "NixOS cloud-init VM template (built by builder:vm-build)"

  # Templates are not started.
  template = true
  started  = false

  # UEFI boot, matching the qcow-efi image (GRUB-EFI) and the nix-builder VM.
  bios    = "ovmf"
  machine = "q35"

  efi_disk {
    datastore_id = var.disk_storage
    type         = "4m"
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  scsi_hardware = "virtio-scsi-single"

  # Import the built qcow2 as the root disk. Changing the image (new build)
  # replaces the template in place. Clones grow this via autoResize.
  disk {
    interface    = "scsi0"
    datastore_id = var.disk_storage
    import_from  = var.vm_image_file
    size         = 8
    discard      = "on"
    ssd          = true
  }

  # Serial console (the qcow-efi image logs to ttyS0).
  serial_device {}

  boot_order = ["scsi0"]
}
