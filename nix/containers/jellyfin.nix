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
  # ships with the standard mesa build; libva-utils provides `vainfo` so the
  # verify task can list the available VAProfile entrypoints.
  hardware.graphics = {
    enable        = true;
    extraPackages = with pkgs; [ libva-utils ];
  };

  # Hint the driver name for jellyfin's bundled ffmpeg. Set on the service (not
  # sessionVariables) so the daemon actually inherits it.
  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "radeonsi";

  # The passed-through /dev/dri/renderD128 is owned by GID 993 (the host `render`
  # group). Pin the container's render group to the same GID and add jellyfin to
  # it so the daemon can open the render node. See device_passthrough in
  # terraform/env-2-production/terraform.tfvars.
  # mkForce overrides NixOS's default render GID (303) to match the host device.
  users.groups.render.gid = lib.mkForce 993;
  users.users.jellyfin.extraGroups = [ "render" "video" ];
}
