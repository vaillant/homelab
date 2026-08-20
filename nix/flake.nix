{
  description = "NixOS LXC images for Proxmox homelab";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # claude-code is not in 24.11; pull just that package from unstable.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-generators, ... }:
    let
      system = "x86_64-linux";
    in
    {
      # Image packages (for building base images)
      packages.${system} = {
        # Unprivileged LXC rootfs tarball (uploaded as a vztmpl).
        proxmox-lxc-base = nixos-generators.nixosGenerate {
          inherit system;
          format = "proxmox-lxc";
          modules = [ ./lxc/base.nix ];
        };

        # Full VM disk image (qcow2, UEFI/GRUB-EFI). Imported into Proxmox and
        # turned into a cloud-init-enabled template. See builder:vm-build.
        proxmox-vm-base = nixos-generators.nixosGenerate {
          inherit system;
          format = "qcow-efi";
          modules = [ ./vm/base.nix ];
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

        jellyfin = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./containers/jellyfin.nix ];
        };

        # Development VM for running the Claude Code CLI. Deployed onto a
        # clone of the VM template via `nixos-rebuild switch` (Phase 4).
        claude-dev = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./vm/claude.nix
            {
              # Source claude-code from unstable while the rest stays on 24.11.
              # claude-code is unfree, so instantiate unstable with allowUnfree
              # and allow the package on the 24.11 side that consumes it.
              nixpkgs.overlays = [
                (final: prev: {
                  claude-code = (import nixpkgs-unstable {
                    inherit system;
                    config.allowUnfree = true;
                  }).claude-code;
                })
              ];
              nixpkgs.config.allowUnfreePredicate = pkg:
                nixpkgs.lib.getName pkg == "claude-code";
            }
          ];
        };
      };
    };
}
