.PHONY: help check check-env fmt \
	get-nixos-lxc builder-init builder-plan builder-apply builder-output \
	build-lxc upload-lxc \
	production-init production-plan production-apply production-output

# Variables
NODE ?= proxmox1
STORAGE ?= local
LXC_IMAGE ?= proxmox-lxc-base
BUILDER ?= ssh://root@nix-builder
NIXOS_VERSION ?= 24.11

# Default target
help:
	@echo "Homelab Infrastructure Management"
	@echo ""
	@echo "⚠️  IMPORTANT: Run 'nix-shell' first to load required tools"
	@echo ""
	@echo "Phase 1: Deploy builder"
	@echo "  make get-nixos-lxc    - Download and upload prebuilt NixOS LXC from Hydra"
	@echo "  make builder-init     - Initialize builder environment"
	@echo "  make builder-plan     - Plan builder changes"
	@echo "  make builder-apply    - Apply builder changes"
	@echo "  make builder-output   - Show builder outputs"
	@echo ""
	@echo "Phase 2: Build NixOS image"
	@echo "  make build-lxc        - Build custom NixOS LXC image"
	@echo "  make upload-lxc       - Upload LXC image to Proxmox"
	@echo ""
	@echo "Phase 3: Deploy production"
	@echo "  make production-init    - Initialize production environment"
	@echo "  make production-plan    - Plan production changes"
	@echo "  make production-apply   - Apply production changes"
	@echo "  make production-output  - Show production outputs"
	@echo ""
	@echo "Utility targets:"
	@echo "  make check-env        - Check required tools"
	@echo "  make check            - Test Proxmox API connection"
	@echo "  make fmt              - Format Terraform files"
	@echo ""
	@echo "Environment variables required:"
	@echo "  PM_API_URL           - Proxmox API URL"
	@echo "  PM_API_TOKEN_ID      - Proxmox API token ID"
	@echo "  PM_API_TOKEN_SECRET  - Proxmox API token secret"

#
# Utility targets
#

check: check-env
	@echo "Testing Proxmox API connection..."
	@curl -s -k -f \
		-H "Authorization: PVEAPIToken=$(PM_API_TOKEN_ID)=$(PM_API_TOKEN_SECRET)" \
		"$(PM_API_URL)/version" | jq -r '"✓ Connected to Proxmox VE v\(.data.version) (\(.data.release))"' \
		|| (echo "✗ Failed to connect to Proxmox API" && exit 1)

check-env:
	@echo "Checking required tools..."
	@command -v nix >/dev/null 2>&1 || \
		(echo "ERROR: nix is not installed" && exit 1)
	@echo "✓ nix is installed"
	@command -v tofu >/dev/null 2>&1 || \
		(echo "ERROR: tofu (OpenTofu) is not available. Run 'nix-shell'" && exit 1)
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

fmt:
	@echo "Formatting Terraform files..."
	cd terraform && tofu fmt -recursive

#
# Phase 1: Deploy builder
#

get-nixos-lxc: check
	@echo "Downloading NixOS $(NIXOS_VERSION) LXC image from Hydra..."
	@mkdir -p nix/result/tarball
	curl -L -o nix/result/tarball/nixos-$(NIXOS_VERSION)-lxc.tar.xz \
		"https://hydra.nixos.org/job/nixos/release-$(NIXOS_VERSION)/nixos.proxmoxLXC.x86_64-linux/latest/download-by-type/file/system-tarball"
	@echo ""
	@echo "Uploading to Proxmox..."
	@curl -s -k -f \
		-H "Authorization: PVEAPIToken=$(PM_API_TOKEN_ID)=$(PM_API_TOKEN_SECRET)" \
		-H "Content-Type: multipart/form-data" \
		-F "content=vztmpl" \
		-F "filename=@nix/result/tarball/nixos-$(NIXOS_VERSION)-lxc.tar.xz" \
		"$(PM_API_URL)/nodes/$(NODE)/storage/$(STORAGE)/upload" \
		| jq -r '"✓ Uploaded: \(.data)"' \
		|| (echo "✗ Failed to upload template" && exit 1)
	@echo ""
	@echo "Template available at: $(STORAGE):vztmpl/nixos-$(NIXOS_VERSION)-lxc.tar.xz"

builder-init:
	@echo "Initializing builder environment..."
	cd terraform/env-1-builder && tofu init

builder-plan: check
	@echo "Planning builder changes..."
	cd terraform/env-1-builder && tofu plan \
		-var="target_node=$(NODE)" \
		-var="ostemplate=$(STORAGE):vztmpl/nixos-$(NIXOS_VERSION)-lxc.tar.xz"

builder-apply: check
	@echo "Applying builder changes..."
	cd terraform/env-1-builder && tofu apply \
		-var="target_node=$(NODE)" \
		-var="ostemplate=$(STORAGE):vztmpl/nixos-$(NIXOS_VERSION)-lxc.tar.xz"

builder-output:
	cd terraform/env-1-builder && tofu output

#
# Phase 2: Build NixOS image
#

build-lxc:
	@echo "Building NixOS LXC image$(if $(BUILDER), on $(BUILDER),)..."
	nix build ./nix#$(LXC_IMAGE) --out-link nix/result \
		$(if $(BUILDER),--builders '$(BUILDER) x86_64-linux - 4 1 big-parallel')
	@echo ""
	@echo "Image built: $$(ls nix/result/tarball/)"
	@echo "Upload with: make upload-lxc"

upload-lxc: check
	@TARBALL_COUNT=$$(ls -1 nix/result/tarball/*.tar.xz 2>/dev/null | wc -l | tr -d ' '); \
	if [ "$$TARBALL_COUNT" -eq 0 ]; then \
		echo "ERROR: No .tar.xz files found. Run 'make build-lxc' first."; \
		exit 1; \
	elif [ "$$TARBALL_COUNT" -gt 1 ]; then \
		echo "ERROR: Multiple tarballs found in nix/result/tarball/:"; \
		ls -1 nix/result/tarball/*.tar.xz; \
		echo "Please remove old builds and run 'make build-lxc' again."; \
		exit 1; \
	fi
	@echo "Uploading NixOS LXC image to $(NODE)..."
	@TARBALL=$$(ls nix/result/tarball/*.tar.xz); \
	FILENAME=$$(basename $$TARBALL); \
	curl -s -k -f \
		-H "Authorization: PVEAPIToken=$(PM_API_TOKEN_ID)=$(PM_API_TOKEN_SECRET)" \
		-H "Content-Type: multipart/form-data" \
		-F "content=vztmpl" \
		-F "filename=@$$TARBALL" \
		"$(PM_API_URL)/nodes/$(NODE)/storage/$(STORAGE)/upload" \
		| jq -r '"✓ Uploaded: \(.data)"' \
		|| (echo "✗ Failed to upload template" && exit 1); \
	echo ""; \
	echo "Template available at: $(STORAGE):vztmpl/$$FILENAME"

#
# Phase 3: Deploy production
#

production-init:
	@echo "Initializing production environment..."
	cd terraform/env-2-production && tofu init

production-plan: check
	@echo "Planning production changes..."
	cd terraform/env-2-production && tofu plan \
		-var="default_storage=$(STORAGE)"

production-apply: check
	@echo "Applying production changes..."
	cd terraform/env-2-production && tofu apply \
		-var="default_storage=$(STORAGE)"

production-output:
	cd terraform/env-2-production && tofu output
