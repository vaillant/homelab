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
      packages.${system} = {
        proxmox-lxc-base = nixos-generators.nixosGenerate {
          inherit system;
          format = "proxmox-lxc";
          modules = [ ./lxc/base.nix ];
        };
      };
    };
}
