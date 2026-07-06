#!/usr/bin/env bash
#
# Create a NixOS cloud-init template in Proxmox
#
# Usage: ./create-nixos-template.sh [proxmox-node] [storage] [template-id]
#
# This script creates a NixOS cloud image using nixos-generators and imports it
# into Proxmox as a template that can be cloned by Terraform.
#
# Requirements:
#   - Nix package manager installed
#   - SSH access to Proxmox host (or run directly on Proxmox node)
#   - nixos-generators (will be installed via nix if not available)
#

set -euo pipefail

# Configuration (can be overridden via arguments)
PROXMOX_NODE="${1:-pve1}"
STORAGE="${2:-local-lvm}"
TEMPLATE_ID="${3:-9000}"
TEMPLATE_NAME="nixos-template"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

info() {
    echo -e "${BLUE}[NOTE]${NC} $*"
}

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    error "Nix package manager is not installed."
    error "Install it from: https://nixos.org/download.html"
    error "Quick install: sh <(curl -L https://nixos.org/nix/install) --daemon"
    exit 1
fi

# Check if running on Proxmox node or remotely
if command -v pvesh &> /dev/null; then
    REMOTE=""
    PROXMOX_HOST="localhost"
    log "Running on Proxmox node"
else
    if [ -z "${PROXMOX_HOST:-}" ]; then
        error "Not running on Proxmox node. Set PROXMOX_HOST environment variable to run remotely."
        error "Example: PROXMOX_HOST=root@proxmox.example.com $0"
        exit 1
    fi
    REMOTE="ssh $PROXMOX_HOST"
    log "Running remotely via SSH to $PROXMOX_HOST"
fi

log "Creating NixOS template on node: $PROXMOX_NODE"
log "Storage: $STORAGE"
log "Template ID: $TEMPLATE_ID"
log "Template Name: $TEMPLATE_NAME"

# Check if template already exists
if $REMOTE qm status $TEMPLATE_ID &> /dev/null; then
    warn "VM with ID $TEMPLATE_ID already exists!"
    read -p "Do you want to delete it and recreate? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Deleting existing VM $TEMPLATE_ID..."
        $REMOTE qm destroy $TEMPLATE_ID
    else
        error "Aborted. Please use a different template ID."
        exit 1
    fi
fi

# Create NixOS configuration for cloud-init
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

cat > "$TEMP_DIR/configuration.nix" << 'EOF'
{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/proxmox-image.nix"
  ];

  # Enable cloud-init
  services.cloud-init = {
    enable = true;
    network.enable = true;
  };

  # Enable QEMU guest agent for Proxmox integration
  services.qemu-guest-agent.enable = true;

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  # Network configuration managed by cloud-init
  networking = {
    useDHCP = false;
    hostName = ""; # Will be set by cloud-init
  };

  # Allow cloud-init to manage users
  users.mutableUsers = true;

  # Helpful packages
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    curl
    wget
  ];

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # System settings
  system.stateVersion = "24.05";
}
EOF

log "Building NixOS image using nixos-generators..."
info "This may take some time on first run (downloads and builds packages)"

# Build qcow2 image
IMAGE_PATH=$(nix run github:nix-community/nixos-generators -- \
    --format qcow \
    --configuration "$TEMP_DIR/configuration.nix" \
    2>&1 | tee /dev/tty | grep -oP '/nix/store/[^ ]+\.qcow2$' | tail -1)

if [ -z "$IMAGE_PATH" ] || [ ! -f "$IMAGE_PATH" ]; then
    error "Failed to build NixOS image"
    exit 1
fi

log "Image built successfully: $IMAGE_PATH"

# Get image size
IMAGE_SIZE=$(du -h "$IMAGE_PATH" | cut -f1)
log "Image size: $IMAGE_SIZE"

# Copy image to Proxmox host if remote
if [ "$PROXMOX_HOST" != "localhost" ]; then
    log "Copying image to Proxmox host..."
    REMOTE_IMAGE_PATH="/tmp/nixos-cloud-image-$TEMPLATE_ID.qcow2"
    scp "$IMAGE_PATH" "$PROXMOX_HOST:$REMOTE_IMAGE_PATH"
    IMAGE_PATH_ON_PROXMOX="$REMOTE_IMAGE_PATH"
else
    IMAGE_PATH_ON_PROXMOX="$IMAGE_PATH"
fi

log "Creating VM $TEMPLATE_ID..."
$REMOTE qm create $TEMPLATE_ID \
    --name "$TEMPLATE_NAME" \
    --memory 2048 \
    --cores 2 \
    --net0 virtio,bridge=vmbr0 \
    --scsihw virtio-scsi-single \
    --agent 1 \
    --ostype l26

log "Importing disk..."
$REMOTE qm importdisk $TEMPLATE_ID "$IMAGE_PATH_ON_PROXMOX" "$STORAGE"

# Get the imported disk name
DISK_NAME="unused0"

log "Attaching disk..."
$REMOTE qm set $TEMPLATE_ID --scsi0 "${STORAGE}:vm-${TEMPLATE_ID}-disk-0"

log "Configuring boot order..."
$REMOTE qm set $TEMPLATE_ID --boot order=scsi0

log "Adding cloud-init drive..."
$REMOTE qm set $TEMPLATE_ID --ide2 "${STORAGE}:cloudinit"

log "Setting cloud-init settings..."
$REMOTE qm set $TEMPLATE_ID --serial0 socket --vga serial0

log "Converting to template..."
$REMOTE qm template $TEMPLATE_ID

# Cleanup
if [ "$PROXMOX_HOST" != "localhost" ]; then
    log "Cleaning up remote temporary files..."
    $REMOTE rm -f "$IMAGE_PATH_ON_PROXMOX"
fi

log ""
log "================================================================"
log "SUCCESS! NixOS template created with ID: $TEMPLATE_ID"
log "================================================================"
log ""
log "Template details:"
log "  - ID: $TEMPLATE_ID"
log "  - Name: $TEMPLATE_NAME"
log "  - Node: $PROXMOX_NODE"
log "  - Storage: $STORAGE"
log ""
log "You can now use this template with Terraform to create VMs."
log "Example Terraform variable:"
log ""
echo "  nixos_vms = {"
echo "    \"my-nixos-vm\" = {"
echo "      target_node = \"$PROXMOX_NODE\""
echo "      cores       = 2"
echo "      memory      = 2048"
echo "      ipconfig0   = \"ip=dhcp\""
echo "    }"
echo "  }"
log ""
log "To clone manually:"
log "  qm clone $TEMPLATE_ID <new-vm-id> --name <new-vm-name>"
log ""
