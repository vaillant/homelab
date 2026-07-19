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

  insecure = true

  # SSH connection for disk operations (uses ssh-agent)
  ssh {
    agent    = true
    username = "root"
  }
}
