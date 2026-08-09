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

variable "username" {
  description = "Normal-user account to create on the builder"
  type        = string
  default     = "vaillant"
}

variable "user_password_hash" {
  description = "SHA-512 crypt hash for the normal user's password (from 1Password)"
  type        = string
  sensitive   = true
  default     = ""
}

# NixOS VM template (Phase 2, VM variant). Set by the `vm-build` task after it
# uploads the freshly built qcow2 to Proxmox. When empty, the template resource
# is not created, so `builder:apply` keeps working before any VM image exists.
variable "vm_image_file" {
  description = "Proxmox volume ID of the imported NixOS VM qcow2 (e.g. 'local:import/nixos-vm-....qcow2'). Empty disables the template."
  type        = string
  default     = ""
}

variable "nixos_template_id" {
  description = "VM ID to assign the NixOS template (env-2-production clones this ID)"
  type        = number
  default     = 9000
}
