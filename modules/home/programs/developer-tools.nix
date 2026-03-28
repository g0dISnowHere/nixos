{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Python
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
