{
  description = "NixOS LXC images for Proxmox homelab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, ... }:
    let
      system = "x86_64-linux";
    in
    {
      # LXC image packages (for building base images)
      packages.${system} = {
        proxmox-lxc-base = nixos-generators.nixosGenerate {
          inherit system;
          format = "proxmox-lxc";
          modules = [ ./lxc/base.nix ];
        };
      };

      # NixOS configurations for remote deployment via:
      # nixos-rebuild switch --target-host root@<ip> --flake ./nix#<name>
      nixosConfigurations = {
        cloudflared = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./containers/cloudflared.nix ];
        };

        pulse = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./containers/pulse.nix ];
        };

        bose-soundtouch = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./containers/bose-soundtouch.nix ];
        };
      };
    };
}
