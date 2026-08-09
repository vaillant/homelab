{ pkgs ? import <nixpkgs> {
    config.allowUnfree = true;  # Required for 1Password CLI
  }
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    opentofu
    go-task
    _1password-cli    # 1Password CLI (unfree), comment out if you do not use 1Password

    # Kubernetes tools
    kubectl         # Kubernetes CLI
    talosctl        # Talos Linux CLI
    cilium-cli      # Cilium CLI
    hubble          # Hubble CLI (Cilium flow observability)
    k9s

    # NixOS deployment: orchestrates Phase 4 `nixos-rebuild switch` from the
    # Mac (evaluates the flake, delegates the x86_64 build to nix-builder via
    # --build-host, copies the closure to the target).
    nixos-rebuild

    # Optional but useful tools
    curl            # HTTP client
    jq              # JSON processing
    yq              # YAML processing
    openssh         # SSH client
  ];

  shellHook = ''
    # Suppress locale warnings on macOS
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

    # Source environment variables from ~/.envrc if it exists
    if [ -f "$HOME/.envrc" ]; then
      echo "Loading environment from ~/.envrc"
      source "$HOME/.envrc"
    fi

    # Sign in to 1Password if available and not already signed in
    if command -v op &>/dev/null; then
      if ! op account list &>/dev/null; then
        echo "Signing in to 1Password..."
        eval $(op signin)
      fi
    fi

    # Set kubeconfig if homelab config exists
    if [ -f "$HOME/.kube/config-homelab" ]; then
      export KUBECONFIG="$HOME/.kube/config-homelab"
    fi

    # Set kubeconfig if homelab config exists
    if [ -f "$HOME/.kube/config-cilium" ]; then
      export KUBECONFIG="$HOME/.kube/config-cilium"
    fi

    echo ""
    echo "Homelab Infrastructure Development Environment"
    echo "Run 'task --list' to see available tasks"
  '';
}
