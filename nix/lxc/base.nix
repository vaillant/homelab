{ modulesPath, lib, pkgs, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  # Unprivileged container settings
  proxmoxLXC = {
    privileged = false;
    manageNetwork = true;
    manageHostName = true;
  };

  # Required for unprivileged containers
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  # Console fix - ensures proper console output
  systemd.services."getty@".enable = false;
  systemd.services."autovt@".enable = false;
  systemd.services.console-getty.enable = true;

  # Nix settings for container environment
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Sandbox doesn't work in unprivileged LXC
    sandbox = false;
  };

  # Disable services that don't work in LXC
  services.fstrim.enable = false;
  boot.isContainer = true;

  # Basic packages - bake into image since nixos-rebuild can be unreliable in LXC
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    htop
  ];

  # Enable SSH
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  system.stateVersion = "24.11";
}
