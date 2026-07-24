variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
  default     = "homelab"
}

variable "talos_version" {
  description = "Talos version (e.g., v1.9.5)"
  type        = string
  default     = "v1.9.5"
}

variable "talos_schematic_id" {
  description = "Talos Image Factory schematic ID"
  type        = string
}

variable "talos_image_url" {
  description = "Full URL to Talos raw disk image"
  type        = string
}

variable "node_count" {
  description = "Number of Talos nodes"
  type        = number
  default     = 3
}

variable "gateway" {
  description = "Network gateway IP"
  type        = string
}

variable "ip_base" {
  description = "IP address base (e.g., 192.168.0.20 creates .201, .202, .203)"
  type        = string
}

variable "node_cores" {
  description = "CPU cores per node"
  type        = number
  default     = 4
}

variable "node_memory" {
  description = "Memory in MB per node"
  type        = number
  default     = 8192
}

variable "node_disk" {
  description = "Disk size in GB per node"
  type        = number
  default     = 50
}

variable "pve_nodes" {
  description = "Comma-separated list of Proxmox nodes"
  type        = string
}

variable "default_storage" {
  description = "Default storage for VM disks"
  type        = string
  default     = "local-zfs"
}

variable "default_bridge" {
  description = "Default network bridge"
  type        = string
  default     = "vmbr0"
}
