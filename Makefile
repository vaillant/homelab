.PHONY: help init plan apply validate fmt clean template-create check-env check-proxmox

# Default target
help:
	@echo "Homelab Infrastructure Management"
	@echo ""
	@echo "⚠️  IMPORTANT: Run 'nix-shell' first to load required tools"
	@echo ""
	@echo "Available targets:"
	@echo "  make check-env        - Check required environment variables and tools"
	@echo "  make check-proxmox    - Test connection to Proxmox API"
	@echo "  make init             - Initialize Terraform"
	@echo "  make plan             - Show planned infrastructure changes"
	@echo "  make apply            - Apply infrastructure changes"
	@echo "  make validate         - Validate Terraform configuration"
	@echo "  make fmt              - Format Terraform files"
	@echo "  make template-create  - Create NixOS template in Proxmox"
	@echo "  make clean            - Clean Terraform cache (preserves state)"
	@echo "  make output           - Show Terraform outputs"
	@echo "  make setup            - Quick setup: init + plan"
	@echo ""
	@echo "Environment variables required:"
	@echo "  PM_API_URL           - Proxmox API URL"
	@echo "  PM_API_TOKEN_ID      - Proxmox API token ID"
	@echo "  PM_API_TOKEN_SECRET  - Proxmox API token secret"
	@echo ""
	@echo "Example .envrc file:"
	@echo "  export PM_API_URL='https://proxmox.example.com:8006/api2/json'"
	@echo "  export PM_API_TOKEN_ID='terraform@pve!terraform-token'"
	@echo "  export PM_API_TOKEN_SECRET='your-secret-here'"
	@echo "  export PM_TLS_INSECURE='true'"

# Test connection to Proxmox API
check-proxmox: check-env
	@echo "Testing Proxmox API connection..."
	@curl -s -k -f \
		-H "Authorization: PVEAPIToken=$(PM_API_TOKEN_ID)=$(PM_API_TOKEN_SECRET)" \
		"$(PM_API_URL)/version" | jq -r '"✓ Connected to Proxmox VE v\(.data.version) (\(.data.release))"' \
		|| (echo "✗ Failed to connect to Proxmox API" && exit 1)

# Check if required tools and environment variables are set
check-env:
	@echo "Checking required tools..."
	@command -v nix >/dev/null 2>&1 || \
		(echo "ERROR: nix is not installed" && \
		 echo "Install from: https://nixos.org/download.html" && \
		 echo "Quick install: sh <(curl -L https://nixos.org/nix/install) --daemon" && \
		 exit 1)
	@echo "✓ nix is installed"
	@command -v tofu >/dev/null 2>&1 || \
		(echo "ERROR: tofu (OpenTofu) is not available" && \
		 echo "Run 'nix-shell' to enter the development environment" && \
		 exit 1)
	@echo "✓ tofu (OpenTofu) is available"
	@echo ""
	@echo "Checking environment variables..."
	@test -n "$(PM_API_URL)" || (echo "ERROR: PM_API_URL is not set" && exit 1)
	@echo "✓ PM_API_URL is set"
	@test -n "$(PM_API_TOKEN_ID)" || (echo "ERROR: PM_API_TOKEN_ID is not set" && exit 1)
	@echo "✓ PM_API_TOKEN_ID is set"
	@test -n "$(PM_API_TOKEN_SECRET)" || (echo "ERROR: PM_API_TOKEN_SECRET is not set" && exit 1)
	@echo "✓ PM_API_TOKEN_SECRET is set"
	@echo ""
	@echo "✅ All checks passed!"

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	cd terraform && tofu init

# Plan infrastructure changes
plan: check-env
	@echo "Planning infrastructure changes..."
	cd terraform && tofu plan

# Apply infrastructure changes
apply: check-env
	@echo "Applying infrastructure changes..."
	cd terraform && tofu apply

# Apply with auto-approve (use with caution)
apply-auto: check-env
	@echo "Applying infrastructure changes (auto-approve)..."
	cd terraform && tofu apply -auto-approve

# Validate Terraform configuration
validate:
	@echo "Validating Terraform configuration..."
	cd terraform && tofu validate

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	cd terraform && tofu fmt -recursive

# Create NixOS template
template-create:
	@echo "Creating NixOS template..."
	@if [ -z "$(NODE)" ]; then \
		echo "Usage: make template-create NODE=pve1 STORAGE=local-lvm TEMPLATE_ID=9000"; \
		exit 1; \
	fi
	./scripts/create-nixos-template.sh $(NODE) $(STORAGE) $(TEMPLATE_ID)

# Show Terraform outputs
output: check-env
	@echo "Terraform outputs:"
	cd terraform && tofu output

# Show Terraform state
state-list: check-env
	@echo "Terraform state:"
	cd terraform && tofu state list

# Refresh Terraform state
refresh: check-env
	@echo "Refreshing Terraform state..."
	cd terraform && tofu refresh

# Clean Terraform cache (preserves state files)
clean:
	@echo "Cleaning Terraform cache..."
	rm -rf terraform/.terraform
	rm -f terraform/.terraform.lock.hcl
	@echo "✓ Cleaned (state files preserved)"

# Quick setup: init + plan
setup: init plan
	@echo ""
	@echo "========================================"
	@echo "Setup complete! Review the plan above."
	@echo "Run 'make apply' to create the infrastructure."
	@echo "========================================"

# Show current Terraform workspace
workspace:
	cd terraform && tofu workspace show

# Variables
NODE ?= pve1
STORAGE ?= local-lvm
TEMPLATE_ID ?= 9000
