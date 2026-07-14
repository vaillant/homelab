variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to create the VM on"
  type        = string
}

variable "description" {
  description = "VM description"
  type        = string
  default     = "NixOS VM managed by Terraform"
}

variable "template_name" {
  description = "Name of the NixOS template to clone from"
  type        = string
  default     = "nixos-template"
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "balloon" {
  description = "Minimum memory in MB for ballooning"
  type        = number
  default     = 1024
}

variable "onboot" {
  description = "Start VM on boot"
  type        = bool
  default     = true
}

variable "startup" {
  description = "Startup order"
  type        = string
  default     = ""
}

variable "networks" {
  description = "List of network configurations"
  type = list(object({
    model  = string
    bridge = string
    tag    = optional(number)
  }))
  default = [{
    model  = "virtio"
    bridge = "vmbr0"
  }]
}

variable "disks" {
  description = "List of disk configurations"
  type = list(object({
    type    = string
    storage = string
    size    = string
    format  = optional(string)
    ssd     = optional(number)
    discard = optional(string)
  }))
  default = [{
    type    = "scsi"
    storage = "local-zfs"
    size    = "32G"
    ssd     = 1
    discard = "on"
  }]
}

variable "ipconfig0" {
  description = "IP configuration (e.g., 'ip=10.0.0.100/24,gw=10.0.0.1' or 'ip=dhcp')"
  type        = string
  default     = "ip=dhcp"
}

variable "ci_user" {
  description = "Cloud-init username"
  type        = string
  default     = "nixos"
}

variable "ci_password" {
  description = "Cloud-init password (hashed)"
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_keys" {
  description = "SSH public keys for cloud-init (newline separated)"
  type        = string
  default     = ""
}
