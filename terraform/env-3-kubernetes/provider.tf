terraform {
  required_version = ">= 1.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.7"
    }
  }
}

provider "proxmox" {
  # Uses environment variables: PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN
  insecure = true
  ssh {
    agent    = false
    username = "root"
  }
}

provider "talos" {}
