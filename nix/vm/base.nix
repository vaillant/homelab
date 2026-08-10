{ lib, pkgs, ... }:

# Base configuration for the NixOS *VM* template (Phase 2, VM variant).
#
# This is the full-machine counterpart to nix/lxc/base.nix. It is built with
# the nixos-generators `qcow-efi` format (see nix/flake.nix), which already
# provides the bootloader (GRUB-EFI, installed to the removable fallback path
# so no NVRAM is needed), an ext4 root labelled `nixos` with autoResize,
# `boot.growPartition = true`, a vfat ESP and a serial console. Do NOT declare
# boot.loader / fileSystems / growPartition here — that is the format's job.
#
# Everything network/identity related (DHCP, hostname, SSH key) is delivered at
# first boot by cloud-init: Proxmox attaches a ConfigDrive/NoCloud drive built
# from the `initialization {}` block in terraform/modules/nixos-vm.

{
  # Cloud-init: read the Proxmox-provided datasource and apply hostname,
  # network configuration (DHCP or static) and the root SSH key.
  services.cloud-init = {
    enable = true;
    network.enable = true; # let cloud-init own networking (DHCP/static)
    settings.datasource_list = [ "NoCloud" "ConfigDrive" ];
  };

  # cloud-init drives the network, so don't also run NixOS's blanket DHCP on
  # every interface (avoids two DHCP clients fighting over the same link).
  networking.useDHCP = lib.mkForce false;

  # Let cloud-init set the hostname from the Proxmox VM name (local-hostname).
  # An empty value tells NixOS not to manage the hostname, so what cloud-init
  # writes at first boot persists — otherwise NixOS forces its default "nixos"
  # and the cloud-init hostname (and thus DHCP/DNS registration) is lost.
  networking.hostName = lib.mkDefault "";

  # systemd-networkd obtains the DHCP lease (and registers its hostname with
  # the DHCP/DNS server) before cloud-init applies the real hostname, so the
  # server first records the boot-time name ("nixos"). Re-run DHCP once
  # cloud-init has finished so the correct hostname gets registered.
  systemd.services.redhcp-after-cloudinit = {
    description = "Re-register DHCP hostname after cloud-init";
    after = [ "cloud-final.service" ];
    wants = [ "cloud-final.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart systemd-networkd.service";
    };
  };

  # QEMU guest agent so Proxmox can report the guest IP and shut down cleanly.
  # (Matches `agent { enabled = true }` in the VM module.)
  services.qemuGuest.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  # Declarative admin user. cloud-init can't grant sudo on NixOS (it lands the
  # user in "users", not "wheel", and NixOS ignores /etc/sudoers.d drop-ins),
  # so the user is defined here instead. Name, password hash and SSH key come
  # from nix/secrets/ (populated by `task secrets-init` from the Taskfile
  # USERNAME var + 1Password). Baked into the image, so every clone has it.
  users.users.${lib.strings.trim (builtins.readFile ../secrets/username)} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = lib.strings.trim (builtins.readFile ../secrets/user-password-hash);
    openssh.authorizedKeys.keys = [
      (lib.strings.trim (builtins.readFile ../secrets/ssh-pubkey))
    ];
  };
  security.sudo.wheelNeedsPassword = false; # passwordless sudo for wheel

  # Allow ping (ICMP)
  networking.firewall.allowPing = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Let wheel members (the deploy user) push unsigned closures to the store,
    # so `nixos-rebuild --target-host <user>@ --use-remote-sudo` can copy the
    # locally-built system without signature errors.
    trusted-users = [ "root" "@wheel" ];
  };

  # Pre-baked packages, same set as the LXC base for consistency.
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    htop
  ];

  system.stateVersion = "24.11";
}
