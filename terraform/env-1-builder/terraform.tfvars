# NixOS builder environment configuration
# Copy to terraform.tfvars and adjust for your setup

target_node = "proxmox1"
ostemplate  = "local:vztmpl/nixos-24.11-lxc.tar.xz"

cores       = 4
memory      = 8192
swap        = 4096
rootfs_size = "64G"

networks = [{
  name   = "eth0"
  bridge = "vmbr0"
  ip     = "dhcp"
}]
