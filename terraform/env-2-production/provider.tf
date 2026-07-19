terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  # Connection details via environment variables:
  # PROXMOX_VE_ENDPOINT  - Proxmox API URL (e.g., "https://proxmox.example.com:8006/")
  # PROXMOX_VE_API_TOKEN - API token (e.g., "user@pam!tokenname=secret")
  # PROXMOX_VE_INSECURE  - Set to "true" to skip TLS verification (optional)
  #
  # Or use username/password:
  # PROXMOX_VE_USERNAME  - Username (e.g., "root@pam")
  # PROXMOX_VE_PASSWORD  - Password

  insecure = true  # Set to false if using valid SSL certificates
}
