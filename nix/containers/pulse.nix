{ config, lib, pkgs, ... }:

let
  # Read Proxmox credentials from secrets files (gitignored)
  proxmoxTokenId = lib.strings.trim (builtins.readFile ../secrets/pulse-proxmox-token-id);
  proxmoxTokenSecret = lib.strings.trim (builtins.readFile ../secrets/pulse-proxmox-token-secret);
in
{
  imports = [
    ../lxc/base.nix
  ];

  # Container hostname
  networking.hostName = "pulse";

  # Enable Docker for running Pulse container
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  # Pulse monitoring container
  virtualisation.oci-containers = {
    backend = "docker";
    containers.pulse = {
      image = "ghcr.io/rcourtman/pulse:latest";
      ports = [ "7655:7655" ];
      environment = {
        # Proxmox connection settings
        PROXMOX_HOST = "https://proxmox1.svaillant.com:8006";
        PROXMOX_TOKEN_ID = proxmoxTokenId;
        PROXMOX_TOKEN_SECRET = proxmoxTokenSecret;
        PROXMOX_VERIFY_SSL = "false";
      };
      volumes = [
        "pulse-data:/app/data"
      ];
    };
  };

  # Open port for Pulse web UI
  networking.firewall.allowedTCPPorts = [ 7655 ];
}
