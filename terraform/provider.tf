terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc08"
    }
  }
}

provider "proxmox" {
  # Connection details via environment variables:
  # PM_API_URL          - Proxmox API URL (e.g., "https://proxmox.example.com:8006/api2/json")
  # PM_API_TOKEN_ID     - API token ID (e.g., "user@pam!tokenname")
  # PM_API_TOKEN_SECRET - API token secret
  # PM_TLS_INSECURE     - Set to "true" to skip TLS verification (optional)

  pm_tls_insecure = true  # Set to false if using valid SSL certificates
}
