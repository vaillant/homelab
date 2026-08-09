{ pkgs, ... }:

# NixOS VM specialized for running the Claude Code CLI.
#
# Deployed onto a clone of the VM template (Phase 3) with:
#   task production:deploy-claude-dev
# which runs `nixos-rebuild switch --target-host root@claude-dev.<dns>`.
#
# base.nix supplies cloud-init/SSH/qemu-guest; hardware.nix supplies the
# bootloader + filesystems needed to switch a live VM.

{
  imports = [
    ./base.nix
    ./hardware.nix
  ];

  # Hostname is set by cloud-init from the Proxmox VM name (see vm/base.nix),
  # so it is intentionally not hardcoded here.

  # Claude Code CLI plus a general-purpose dev toolchain. claude-code comes
  # from the nixpkgs-unstable overlay defined in flake.nix.
  environment.systemPackages = with pkgs; [
    claude-code
    nodejs_22
    gcc
    gnumake
    ripgrep
    fd
    jq
  ];

  # Claude Code shells out to git (already provided by base.nix) and expects a
  # non-tiny /tmp; the default tmpfs is fine for the 8 GB RAM this VM gets.
}
