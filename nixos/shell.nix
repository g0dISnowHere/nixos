{ config, pkgs, lib, ... }:

{
  # users.defaultUserShell = pkgs.zsh; # Make zsh the default shell for all users.

  # environment.systemPackages = with pkgs; [
  #   # Python - Enhanced for global package management
  #   python3Full # Full Python installation with all modules
  #   python3Packages.pip # Standalone pip for global installs
  #   python3Packages.setuptools # For building packages
  #   python3Packages.wheel # For wheel support
  #   python3Packages.virtualenv # Virtual environment support
  #   python3Packages.pipx # Install Python apps in isolated environments
  #   uv # Fast Python package installer

  #   # Go - Complete toolchain
  #   go # Go compiler and tools
  #   gopls # Go language server
  #   go-tools # Additional Go tools (goimports, etc.)

  #   # JavaScript/Node.js - Complete ecosystem
  #   nodejs # Node.js runtime
  #   npm-check-updates # Update npm packages
  #   yarn # Alternative package manager
  #   pnpm # Fast package manager

  #   # Rust - Complete toolchain
  #   rustc # Rust compiler
  #   cargo # Rust package manager
  #   rust-analyzer # Rust language server
  #   clippy # Rust linter
  #   rustfmt # Rust formatter

  #   # Package managers and build tools
  #   pkgconf # pkg-config replacement
  #   gcc # C compiler for native extensions
  #   gnumake # Build tool
  #   cmake # Cross-platform build system
  # ];

  # # Environment variables for global package installation
  # environment.variables = {
  #   # Python: Allow pip to install packages globally (use with caution)
  #   PIP_BREAK_SYSTEM_PACKAGES = "1";

  #   # Go: Set GOPATH and GOBIN for global installs
  #   GOPATH = "$HOME/go";
  #   GOBIN = "$HOME/go/bin";

  #   # Node.js: Set npm global prefix
  #   NPM_CONFIG_PREFIX = "$HOME/.npm-global";

  #   # Rust: Cargo installs to ~/.cargo/bin by default
  #   CARGO_HOME = "$HOME/.cargo";
  # };

  # # Update PATH to include global package installation directories
  # environment.shellInit = ''
  #   # Add Go binaries to PATH
  #   export PATH="$HOME/go/bin:$PATH"

  #   # Add npm global binaries to PATH
  #   export PATH="$HOME/.npm-global/bin:$PATH"

  #   # Add Cargo binaries to PATH (usually already included)
  #   export PATH="$HOME/.cargo/bin:$PATH"

  #   # Add pipx binaries to PATH
  #   export PATH="$HOME/.local/bin:$PATH"
  # '';

  # programs.npm.enable = true; # Enable npm completion and configuration

  # programs.direnv.enable = true; # Enable direnv for per-project environments

  programs.zsh = {
    # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zsh.enable
    enable = true;
    # autosuggestion.enable = true; # home manager
    autosuggestions.enable = true; # configuration.nix
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    # enableVteIntegration = true;

    # shellAliases = {
    #   # ll = "ls -l";

    #   update = "cd ~/Documents/01_config/mine && nix flake update";

    #   switch =
    #     "cd ~/Documents/01_config/mine && sudo nixos-rebuild switch --flake .#";

    #   test =
    #     "cd ~/Documents/01_config/mine && sudo nixos-rebuild test --flake .#";

    # };
    # history.size = 10000;
    # oh-my-zsh = { # home manager
    ohMyZsh = { # configuration.nix
      enable = true;
      plugins = [
        "git"
        # "thefuck"
        "tailscale"
        "docker"
        "docker-compose"
        "vscode"
        "git"
        "direnv"
      ];
      theme = "robbyrussell";
    };
  };

  # # Allow passwordless sudo for nixos-rebuild
  # security.sudo.extraConfig = ''
  #   djoolz ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/nixos-rebuild
  # '';
}
