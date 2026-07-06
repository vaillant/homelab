# Global variables for the Proxmox infrastructure

variable "proxmox_nodes" {
  description = "List of Proxmox nodes in the cluster"
  type        = list(string)
  default     = ["pve1", "pve2", "pve3"]
}

variable "default_storage" {
  description = "Default storage for VMs and containers"
  type        = string
  default     = "local-lvm"
}

variable "default_bridge" {
  description = "Default network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ssh_public_keys" {
  description = "SSH public keys to add to VMs and containers (newline separated)"
  type        = string
  default     = ""
}

variable "nixos_template" {
  description = "Name of the NixOS template"
  type        = string
  default     = "nixos-template"
}
