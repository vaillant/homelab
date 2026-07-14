variable "hostname" {
  description = "Container hostname"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to create the container on"
  type        = string
}

variable "ostemplate" {
  description = "OS template (e.g., 'local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst')"
  type        = string
}

variable "description" {
  description = "Container description"
  type        = string
  default     = "LXC container managed by Terraform"
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 512
}

variable "swap" {
  description = "Swap in MB"
  type        = number
  default     = 512
}

variable "onboot" {
  description = "Start container on boot"
  type        = bool
  default     = true
}

variable "start" {
  description = "Start container after creation"
  type        = bool
  default     = true
}

variable "unprivileged" {
  description = "Run as unprivileged container"
  type        = bool
  default     = true
}

variable "rootfs_storage" {
  description = "Storage for root filesystem"
  type        = string
  default     = "local-zfs"
}

variable "rootfs_size" {
  description = "Size of root filesystem"
  type        = string
  default     = "8G"
}

variable "networks" {
  description = "List of network configurations"
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

variable "mountpoints" {
  description = "Additional mount points"
  type = map(object({
    storage = string
    size    = string
    mp      = string
  }))
  default = {}
}

variable "ssh_keys" {
  description = "SSH public keys (newline separated)"
  type        = string
  default     = ""
}

variable "password" {
  description = "Root password"
  type        = string
  sensitive   = true
  default     = null
}

variable "features_nesting" {
  description = "Enable nesting (required for NixOS, Docker, etc.)"
  type        = bool
  default     = true
}

variable "features_fuse" {
  description = "Enable FUSE"
  type        = bool
  default     = false
}
