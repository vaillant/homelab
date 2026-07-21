# Homelab Infrastructure as Code

Terraform/OpenTofu configuration for managing a Proxmox VE cluster with NixOS VMs and LXC containers.

## Features

- Modular design for easy scaling
- Support for multiple NixOS VMs
- Support for LXC containers
- Cloud-init integration for automated provisioning
- Automated NixOS template creation
- Environment variable-based authentication
- Nix-based development environment (no global tool installation needed)
- Makefile for simplified workflow

## Directory Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── nixos-vm/          # Reusable NixOS VM module
│   │   └── lxc-container/     # Reusable LXC container module
│   ├── main.tf                # Main configuration (VM and container definitions)
│   ├── provider.tf            # Proxmox provider configuration
│   ├── variables.tf           # Variable definitions
│   ├── versions.tf            # Type definitions for VMs and containers
│   ├── outputs.tf             # Output definitions
│   └── terraform.tfvars.example  # Example configuration
├── scripts/
│   └── create-nixos-template.sh  # Script to create NixOS cloud template
├── shell.nix                  # Nix development environment
├── Makefile                   # Task automation
└── README.md
```

## Prerequisites

1. **Nix Package Manager** (only requirement!)
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```

2. **Proxmox VE Cluster**
   - Proxmox cluster (or modify `proxmox_nodes` variable)
   - API token created for Terraform access
   - SSH access available for Terraform access

All other tools (OpenTofu, 1Password CLI, etc.) are provided by the Nix shell environment.

## TODOs

* Currently root SSH access assumed. Change to normal use access.
* Update Token Rights (see Proxmox Roles)
* Check: Why is the private SSH Key required?
* Cleanup checks in Taskfile
* Add tags to created VM.
* Change to default nix, away from DeterminateSystems 

Very Minor:
* Ubiquiti Web UI does not show correct hostname, but "ubuntu" for nix-builder. IMHO a Ubiquiti bug.

## Quick Start

### 1. Enter the Development Environment

```bash
# Clone the repository and enter the directory
cd homelab

# Enter the Nix shell (provides all tools)
nix-shell

# You now have access to: tofu, op (1Password CLI), make, jq, etc.
```

### 2. Create Proxmox API Token

On your Proxmox server:

```bash
# Create a user for Terraform
pveum user add terraform@pve

# Create a role with necessary permissions
pveum role add TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Pool.Allocate Pool.Audit SDN.Use Sys.Audit Sys.Console Sys.Modify"

# Assign role to user
# TODO: CHeck: Is wrong, the "/" should be assigned to the token?
$ Maybe not, as we do not have privelege seperation?
pveum aclmod / -user terraform@pve -role TerraformRole

# Create API token
pveum user token add terraform@pve terraform-token --privsep 0
```

Save the token ID and secret - you'll need them for the next step.

### 3. Configure Environment Variables

Create a `~/.envrc` file (this file is git-ignored):

```bash
cat > ~/.envrc << 'EOF'
export PM_API_URL="https://your-proxmox-host.example.com:8006/api2/json"
export PM_API_TOKEN_ID="terraform@pve!terraform-token"
export PM_API_TOKEN_SECRET="your-secret-here"
export PM_TLS_INSECURE="true"  # Set to false if using valid SSL certificates
EOF
```

**Alternative: Using 1Password CLI**

```bash
cat > ~/.envrc << 'EOF'
# Reference secrets from 1Password
export PM_API_URL="op://Private/Proxmox/url"
export PM_API_TOKEN_ID="op://Private/Proxmox/token_id"
export PM_API_TOKEN_SECRET="op://Private/Proxmox/token_secret"
export PM_TLS_INSECURE="true"
EOF
```

### 4. Download NixOS LX container image and upload 

```bash
  make download-nixos-lxc
  make upload-lxc NODE=<nodename>
```


### 4. Create NixOS Template

```bash
# Create the template on node pve1
make template-create NODE=pve1 STORAGE=local-lvm TEMPLATE_ID=9000

# Or run the script directly
./scripts/create-nixos-template.sh pve1 local-lvm 9000
```

This will:
1. Build a NixOS cloud image using nixos-generators
2. Import it into Proxmox
3. Configure cloud-init support
4. Convert to a template

### 5. Configure Your Infrastructure

```bash
# Copy example configuration
cd terraform
cp terraform.tfvars.example terraform.tfvars

# Edit with your configuration
vim terraform.tfvars
```

Example `terraform.tfvars`:

```hcl
proxmox_nodes = ["pve1", "pve2", "pve3"]

ssh_public_keys = <<-EOT
ssh-ed25519 AAAAC3Nza... user@host
EOT

nixos_vms = {
  "nixos-web-01" = {
    target_node = "pve1"
    cores       = 2
    memory      = 4096
    ipconfig0   = "ip=10.0.0.100/24,gw=10.0.0.1"
  }
}

lxc_containers = {
  "docker-host" = {
    target_node = "pve1"
    ostemplate  = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
    cores       = 2
    memory      = 2048
    features_nesting = true
  }
}
```

### 6. Deploy Infrastructure

```bash
# Return to repo root
cd ..

# Quick setup: initialize and plan
make setup

# Apply the configuration
make apply
```


## Troubleshooting

tail -f /var/log/cloud-init-output.log 


### Nix Shell Issues

```bash
# If nix-shell fails, try:
nix-shell --pure

# Or rebuild the environment:
nix-collect-garbage
nix-shell
```

## Security Notes

1. **Never commit `.envrc`** - it contains secrets (already in `.gitignore`)
2. **Never commit `terraform.tfvars`** - it may contain sensitive data
3. **Use 1Password CLI** for managing secrets in teams
4. **Rotate API tokens** regularly
5. **Use least-privilege** API token permissions

## Tips

- Use `direnv` to automatically load `.envrc`:
  ```bash
  # Install direnv
  nix-env -iA nixpkgs.direnv

  # Allow .envrc
  direnv allow
  ```

- Format code before committing:
  ```bash
  make fmt
  ```

- Validate configuration:
  ```bash
  make validate
  ```

## Sources

- [Terraform Proxmox Provider (telmate)](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-generators](https://github.com/nix-community/nixos-generators)
- [NixOS Discourse - Cloud-init for Proxmox](https://discourse.nixos.org/t/a-cloudinit-image-for-use-in-proxmox/27519)
- [NixOS Wiki - Proxmox Virtual Environment](https://nixos.wiki/wiki/Proxmox_Virtual_Environment)
- [GitHub - Abdullahjalaly/nixos-cloud-image](https://github.com/Abdullahjalaly/nixos-cloud-image)

## License

MIT
