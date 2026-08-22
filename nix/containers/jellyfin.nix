{ config, lib, pkgs, ... }:

let
  # NAS SMB target, read at build time from a gitignored secrets file (mirrors
  # nix/secrets/ssh-pubkey). Format: //host/share  e.g. //synology.svaillant.com/SharedData
  # Host and share name are non-secret; the username/password live in an
  # out-of-band EnvironmentFile (see below), never in the nix store.
  nasUnc   = lib.removePrefix "//" (lib.strings.trim (builtins.readFile ../secrets/nas-share));
  nasParts = lib.splitString "/" nasUnc;
  nasHost  = builtins.head nasParts;
  nasShare = lib.concatStringsSep "/" (builtins.tail nasParts);
in
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
  # only for driver libraries. rclone is the userspace SMB client for /srv/nas.
  environment.systemPackages = with pkgs; [ libva-utils rclone ];

  # NAS media over SMB, mounted read-write at /srv/nas alongside the local
  # /srv/media volume.
  #
  # Why rclone/FUSE and not native cifs: this is an unprivileged LXC, and the
  # kernel refuses to mount `cifs` inside a user namespace (cifs lacks
  # FS_USERNS_MOUNT) — even with the Proxmox mount=cifs feature it returns EPERM.
  # FUSE *is* user-namespace mountable, so rclone (a userspace SMB client) mounts
  # the share via FUSE. The container is granted the Proxmox `fuse=1` feature
  # (features_fuse on svc-jellyfin in terraform/env-2-production/terraform.tfvars).
  #
  # Host + share name come from nix/secrets/nas-share (non-secret, staged at
  # deploy time). The username and obscured password live in
  # /etc/nixos-secrets/rclone-nas.env, delivered out-of-band by
  # `task production:deploy-jellyfin` so they never enter the nix store.
  programs.fuse.userAllowOther = true;

  # Mountpoint owned by jellyfin so it can read/write the share.
  systemd.tmpfiles.rules = [ "d /srv/nas 0755 jellyfin jellyfin - -" ];

  systemd.services.rclone-nas = {
    description = "rclone FUSE mount of the NAS SMB share at /srv/nas";
    after    = [ "network-online.target" ];
    wants    = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    # rclone needs fusermount3 on PATH to (un)mount the FUSE filesystem.
    path = [ pkgs.fuse3 ];
    environment = {
      RCLONE_CONFIG_NAS_TYPE = "smb";
      RCLONE_CONFIG_NAS_HOST = nasHost;
    };
    serviceConfig = {
      Type = "notify";                 # rclone signals readiness once the mount is live
      # Credentials (RCLONE_CONFIG_NAS_USER / _PASS) — systemd reads this as root
      # before dropping privileges, so it can stay 0600 root-owned.
      EnvironmentFile = "/etc/nixos-secrets/rclone-nas.env";
      CacheDirectory  = "rclone-nas";  # /var/cache/rclone-nas for --vfs-cache-mode writes
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount NAS:${nasShare} /srv/nas \
          --config=/dev/null \
          --allow-other \
          --dir-perms 0777 --file-perms 0666 --umask 000 \
          --vfs-cache-mode writes \
          --cache-dir /var/cache/rclone-nas \
          --dir-cache-time 12h \
          --poll-interval 1m
      '';
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u /srv/nas";
      Restart = "on-failure";
      RestartSec = 10;
    };
  };

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
