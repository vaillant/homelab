{ modulesPath, ... }:

# Bootable hardware profile for Phase 4 (`nixos-rebuild switch`) onto a running
# VM clone. The qcow-efi image (nix/flake.nix) established this layout at build
# time via the nixos-generators format; switching a live machine needs the same
# facts declared so NixOS can (re)install the bootloader and mount the disks.
# Keep this in sync with formats/qcow-efi.nix. It is imported only by VM
# nixosConfigurations, never by the image build (which gets it from the format).

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix") # virtio drivers in initrd
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true; # fallback \EFI\BOOT path, no NVRAM needed
    device = "nodev";
  };
  boot.loader.timeout = 0;
  boot.growPartition = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };
}
