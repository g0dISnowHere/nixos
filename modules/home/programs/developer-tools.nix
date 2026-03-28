{ pkgs, pkgs-unstable, ... }: {
  home.packages = with pkgs; [
    # Python
    python3
    python3Packages.pip
    python3Packages.setuptools
    python3Packages.wheel
    python3Packages.virtualenv
    python3Packages.pipx
    uv

    # Go
    go
    gopls
    go-tools

    # JavaScript / Node.js
    nodejs
    npm-check-updates
    yarn
    pnpm

    # Rust
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt

    # Native build tooling
    pkgconf
    gcc
    gnumake
    cmake

    # Developer-focused newer packages
    pkgs-unstable.devenv
    pkgs-unstable.vscode
    pkgs-unstable.gh
  ];

  home.sessionVariables = {
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    CARGO_HOME = "$HOME/.cargo";
  };

  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.npm-global/bin"
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
  ];
}
