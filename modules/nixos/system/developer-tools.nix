{ pkgs, pkgs-unstable, ... }: {
  environment.systemPackages = with pkgs; [
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
    pkgs-unstable.gh
  ];

  environment.etc."profile.d/developer-tools.sh".text = ''
    export GOPATH="$HOME/go"
    export GOBIN="$HOME/go/bin"
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export CARGO_HOME="$HOME/.cargo"
    export PATH="$HOME/go/bin:$HOME/.npm-global/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
  '';
}
