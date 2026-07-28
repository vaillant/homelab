terraform {
  # The upstream module requires >= 1.5.0
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.76.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">= 0.10.0, < 0.11.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.2"
    }
  }
}

provider "proxmox" {
  # Uses environment variables (set by the root Taskfile):
  #   PROXMOX_VE_ENDPOINT, PROXMOX_VE_API_TOKEN, PROXMOX_VE_SSH_PRIVATE_KEY
  insecure = true
  ssh {
    # SSH is required by bpg/proxmox for image download / disk operations.
    agent    = false
    username = "root"
  }
}

provider "talos" {}
