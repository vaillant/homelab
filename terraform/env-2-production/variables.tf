variable "default_storage" {
  description = "Default storage for VMs and containers"
  type        = string
  default     = "local-zfs"
}

variable "default_bridge" {
  description = "Default network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ssh_public_keys" {
  description = "SSH public keys (newline separated)"
  type        = string
  default     = ""
}

variable "nixos_template_id" {
  description = "VM ID of the NixOS template to clone from"
  type        = number
  default     = 9000
}

variable "nixos_vms" {
  description = "Map of NixOS VMs to create"
  type = map(object({
    target_node = string
    description = optional(string)
    cores       = optional(number)
    sockets     = optional(number)
    memory      = optional(number)
    balloon     = optional(number)
    onboot      = optional(bool)
    startup     = optional(string)
    networks = optional(list(object({
      model  = string
      bridge = string
      tag    = optional(number)
    })))
    disks = optional(list(object({
      type    = string
      storage = string
      size    = string
      format  = optional(string)
      ssd     = optional(number)
      discard = optional(string)
    })))
    ipconfig0 = optional(string)
    ci_user   = optional(string)
  }))
  default = {}
}

variable "lxc_containers" {
  description = "Map of LXC containers to create"
  type = map(object({
    target_node    = string
    ostemplate     = string
    description    = optional(string)
    cores          = optional(number)
    memory         = optional(number)
    swap           = optional(number)
    onboot         = optional(bool)
    start          = optional(bool)
    unprivileged   = optional(bool)
    rootfs_storage = optional(string)
    rootfs_size    = optional(string)
    networks = optional(list(object({
      name   = string
      bridge = string
      ip     = optional(string)
      gw     = optional(string)
      tag    = optional(number)
    })))
    mountpoints = optional(map(object({
      storage = string
      size    = string
      mp      = string
    })))
    features_nesting = optional(bool)
    features_fuse    = optional(bool)
  }))
  default = {}
}
