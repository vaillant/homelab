# Homelab Infrastructure as Code

Terraform/OpenTofu configuration for managing a Proxmox VE cluster with NixOS VMs and LXC containers.

## Features

- Declarative DataCenter 1/3: Terraform automated Proxomox Ubuntu installation, complete with cloud-init, DHCP, DNS, Nix installed.  
- Declarative DataCenter 2/3: Create NixOS LXC Container(s) with remote Nix Builder.
- Nix-based development environment (no global tool installation needed)
- Taskfile for simplified workflow

## Directory Structure

TODO

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

# Create a role with necessary permissions: TODO
pveum role add TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit Pool.Allocate Pool.Audit SDN.Use Sys.Audit Sys.Console Sys.Modify"

# Assign role to user
# TODO: CHeck: Is wrong, the "/" should be assigned to the token?
$ Maybe not, as we do not have privelege seperation?
pveum aclmod / -user terraform@pve -role TerraformRole

# Create API token
pveum user token add terraform@pve terraform-token --privsep 0
```

Save the token ID and secret - you'll need them for the next step.

### 3. Configure 1Password Vault

Environment variables are managed automatically via Taskfile using 1Password CLI. Create the following items in your 1Password vault:

**1Password Item: `Homelab/Proxmox`**
| Field | Description | Example |
|-------|-------------|---------|
| `url` | Proxmox API URL | `https://proxmox.example.com:8006/api2/json` |
| `token_id` | API token ID | `terraform@pve!terraform-token` |
| `token_secret` | API token secret | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |

**1Password Item: `Homelab/Homelab SSH Key`**
| Field | Description |
|-------|-------------|
| `public key` | SSH public key for VM access |
| `private key` | SSH private key (used by Terraform for disk operations) |

The Taskfile automatically reads these secrets:
```yaml
env:
  PROXMOX_VE_ENDPOINT:
    sh: op read "op://Homelab/Proxmox/url" | sed 's|/api2/json||'
  PROXMOX_VE_API_TOKEN:
    sh: echo "$(op read 'op://Homelab/Proxmox/token_id')=$(op read 'op://Homelab/Proxmox/token_secret')"
  PROXMOX_VE_INSECURE: "true"
  PROXMOX_VE_SSH_PRIVATE_KEY:
    sh: op read "op://Homelab/Homelab SSH Key/private key"
```

Verify your setup:
```bash
nix-shell
task check
```

### 4. Deploy the Nix Builder VM

The nix-builder is an Ubuntu VM with Nix installed, used as a remote builder for creating NixOS images. This is necessary when your local machine has a different architecture (e.g., ARM Mac) than Proxmox (x86_64).

```bash
# Enter nix-shell if not already
nix-shell

# Initialize Terraform (first time only)
task builder-init

# Preview changes
task builder-plan

# Deploy the builder VM
task builder-apply
```

The builder VM will be created with:
- Ubuntu 24.04 cloud image
- Nix package manager (Determinate Systems installer)
- QEMU guest agent
- SSH access configured via your 1Password SSH key

Wait 2-3 minutes for cloud-init to complete, then verify:
```bash
# Get the builder IP
task builder-output

# Test SSH and Nix installation
ssh root@<builder-ip> nix --version
```

Once the builder is ready, you can use it for Phase 2 (building NixOS images):
```bash
task build-lxc
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

- [Terraform Proxmox Provider (bpg)](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-generators](https://github.com/nix-community/nixos-generators)
- [NixOS Discourse - Cloud-init for Proxmox](https://discourse.nixos.org/t/a-cloudinit-image-for-use-in-proxmox/27519)
- [NixOS Wiki - Proxmox Virtual Environment](https://nixos.wiki/wiki/Proxmox_Virtual_Environment)
- [GitHub - Abdullahjalaly/nixos-cloud-image](https://github.com/Abdullahjalaly/nixos-cloud-image)

## License

MIT
