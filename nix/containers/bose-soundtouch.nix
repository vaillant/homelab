{ config, lib, pkgs, ... }:

let
  # AfterTouch service binary from GitHub releases
  aftertouch-service = pkgs.stdenv.mkDerivation rec {
    pname = "aftertouch-service";
    version = "0.118.0";

    src = pkgs.fetchurl {
      url = "https://github.com/gesellix/bose-soundtouch/releases/download/v${version}/soundtouch-service-v${version}-linux-amd64";
      sha256 = lib.fakeSha256; # TODO: Replace with actual hash after first build
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/soundtouch-service
      chmod +x $out/bin/soundtouch-service
    '';
  };
in
{
  imports = [
    ../lxc/base.nix
  ];

  # Container hostname
  networking.hostName = "bose-soundtouch";

  # AfterTouch systemd service
  systemd.services.aftertouch = {
    description = "AfterTouch - Bose SoundTouch local service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${aftertouch-service}/bin/soundtouch-service";
      Restart = "always";
      RestartSec = 5;
      # Run as dedicated user for security
      DynamicUser = true;
      # Allow binding to port 8000
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    };
  };

  # Open ports for AfterTouch web UI
  networking.firewall.allowedTCPPorts = [ 8000 ];

  # Note: DNS redirection for Bose speakers needs to be configured separately
  # The speakers need to resolve lookup.bose.com to this container's IP
}
