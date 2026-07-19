variable "target_node" {
  description = "Proxmox node to create the builder on"
  type        = string
  default     = "proxmox1"
}

variable "nixos_version" {
  description = "NixOS version to download"
  type        = string
  default     = "24.11"
}

variable "storage" {
  description = "Storage for ISO/image files"
  type        = string
  default     = "local"
}

variable "disk_storage" {
  description = "Storage for VM disks"
  type        = string
  default     = "local-zfs"
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

variable "disk_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 64
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "IP address (CIDR notation or 'dhcp')"
  type        = string
  default     = "dhcp"
}

variable "gateway" {
  description = "Gateway IP (optional, not needed for DHCP)"
  type        = string
  default     = ""
}

variable "ssh_pubkey" {
  description = "SSH public key for cloud-init"
  type        = string
}
