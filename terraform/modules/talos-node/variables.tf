variable "vm_name" {
  description = "Name of the Talos VM"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to create the VM on"
  type        = string
}

variable "disk_storage" {
  description = "Storage for VM disk"
  type        = string
  default     = "local-zfs"
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
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
  description = "Disk size in GB"
  type        = number
  default     = 50
}

variable "talos_image_id" {
  description = "File ID of the Talos disk image"
  type        = string
}
