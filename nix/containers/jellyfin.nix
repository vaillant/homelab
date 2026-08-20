{ config, lib, pkgs, ... }:

{
  imports = [
    ../lxc/base.nix
  ];

  # Container hostname
  networking.hostName = "svc-jellyfin";

  # Jellyfin media server. Runs as the `jellyfin` system user/group and opens
  # its web/discovery ports (8096, 8920, 1900, 7359) via openFirewall.
  services.jellyfin = {
    enable      = true;
    openFirewall = true;
  };

  # AMD RDNA3 (Phoenix2) hardware transcode via VAAPI. NixOS 24.11 uses
  # hardware.graphics (formerly hardware.opengl). The radeonsi VAAPI driver
  # ships with the standard mesa build, so enabling graphics is enough.
  hardware.graphics.enable = true;

  # vainfo (from libva-utils) for verifying VAAPI. It's a CLI tool, so it belongs
  # on PATH via systemPackages — NOT in hardware.graphics.extraPackages, which is
  # only for driver libraries.
  environment.systemPackages = with pkgs; [ libva-utils ];

  # Hint the driver name for jellyfin's bundled ffmpeg. Set on the service (not
  # sessionVariables) so the daemon actually inherits it.
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "radeonsi";

  # /dev/dri/renderD128 is passed through owned (in-container) by the `render`
  # group at NixOS's default GID 303 — see device_passthrough in
  # terraform/env-2-production/terraform.tfvars. Adding jellyfin to render (and
  # video) lets the daemon open the render node for VAAPI. No GID override is
  # needed, which keeps this working across rebuilds.
  users.users.jellyfin.extraGroups = [ "render" "video" ];
}
