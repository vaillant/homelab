# Claude.md - Project Guidelines

This file documents architectural decisions and guidelines for Claude Code.

## Task Runner and Mandatory Configuration: Taskfile

**Decision:** Use [Taskfile](https://taskfile.dev) for all coammnds that must be run. Also centralize all mandatory configuration to this file (Proxmox credentials, node names, storage names, ...). 

## Local dependencies: nix-shell

**Decision:** All locally required tools are installed using nix. No preconditions (except nix) are needed to be fullfilled. To admin this environment, use ```nix-shell```. 

## VM and LXC Container OS: NixOS

**Decision:** All LXC containers and VM's shoudl be NixOS based. They are build using nix locally. Because of this, a builder is needed first to build the different NixOs VM and LXC. To build these, the builder is created on the Proxmox cluster in case the local PC has a different architecture than Proxmox (PC has ARM, Proxmox has x86). 

## Terraform and Terraform Provider: Tofu and bpg/proxmox

**Decision:** Use Tofu as Terraform engine. Use the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox) provider instead of telmate/proxmox. The bpg provider is actively maintained, has better documentation, and uses environment variables `PROXMOX_VE_ENDPOINT` and `PROXMOX_VE_API_TOKEN` for authentication.

## Deployment Phases

1. **Phase 1: Deploy builder** - Set up NixOS build infrastructure
2. **Phase 2: Build NixOS image** - Build custom LXC images
3. **Phase 3: Deploy production** - Deploy VMs and containers
## Project Structure

```
homelab/
├── Taskfile.yml          # Task definitions
├── nix/
│   ├── flake.nix         # NixOS image definitions
│   └── lxc/
│       └── base.nix      # Base NixOS LXC configuration
└── terraform/
    ├── env-1-builder/    # NixOS builder environment
    ├── env-2-production/ # Production VMs and containers
    └── modules/          # Reusable Terraform modules
```


