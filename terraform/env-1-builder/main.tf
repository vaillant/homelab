# NixOS builder environment
# Manages the nix-builder LXC container for building NixOS images

module "nix_builder" {
  source = "../modules/lxc-container"

  hostname    = "nix-builder"
  target_node = var.target_node
  ostemplate  = var.ostemplate
  description = "NixOS remote builder"

  cores  = var.cores
  memory = var.memory
  swap   = var.swap

  onboot = true
  start  = true

  unprivileged = true
  rootfs_size  = var.rootfs_size

  networks = var.networks

  ssh_keys = var.ssh_public_keys

  features_nesting = true
}
