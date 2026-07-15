variable "target_node" {
  description = "Proxmox node to create the builder on"
  type        = string
  default     = "pve"
}

variable "ostemplate" {
  description = "NixOS LXC template"
  type        = string
  default     = "local:vztmpl/nixos-24.11-lxc.tar.xz"
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 8192
}

variable "swap" {
  description = "Swap in MB"
  type        = number
  default     = 4096
}

variable "rootfs_size" {
  description = "Root filesystem size"
  type        = string
  default     = "64G"
}

variable "networks" {
  description = "Network configuration"
  type = list(object({
    name   = string
    bridge = string
    ip     = optional(string)
    gw     = optional(string)
    tag    = optional(number)
  }))
  default = [{
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }]
}

variable "ssh_public_keys" {
  description = "SSH public keys"
  type        = string
  default     = ""
}
