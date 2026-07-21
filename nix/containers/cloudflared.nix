{ config, lib, pkgs, ... }:

let
  # Read tunnel token from secrets file (gitignored)
  tunnelToken = builtins.readFile ../secrets/cloudflared-token;
in
{
  imports = [
    ../lxc/base.nix
  ];

  # Container hostname
  networking.hostName = "cloudflared";

  # Cloudflare Tunnel service
  services.cloudflared = {
    enable = true;
    tunnels = {
      "homelab" = {
        credentialsFile = pkgs.writeText "cloudflared-credentials" tunnelToken;
        default = "http_status:404";
        # Add ingress rules as needed:
        # ingress = {
        #   "example.domain.com" = "http://localhost:8080";
        # };
      };
    };
  };

  # Cloudflared only needs outbound connectivity, no ports exposed
  networking.firewall.enable = true;
}
