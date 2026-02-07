# Technology Stack

**Analysis Date:** 2026-02-04

## Languages

**Primary:**
- Nix - Configuration management and system declaration via declarative language
- Bash - Shell scripting for system initialization and automation

**Secondary:**
- Python 3 - Global tooling (pip, setuptools, wheel, virtualenv, pipx, uv)
- Go - Complete toolchain with language server (gopls) and tools
- Rust - Complete toolchain with compiler, package manager (cargo), language server, linter (clippy), formatter (rustfmt)
- JavaScript/Node.js - Runtime with npm, yarn, pnpm package managers
- YAML - Configuration file formatting

## Runtime

**Environment:**
- NixOS 25.11 (via `nixpkgs`) - Stable release channel
- NixOS unstable (via `nixpkgs-unstable`) - Bleeding-edge packages for development tools
- Linux kernel - Target OS (x86_64-linux and aarch64-linux supported)

**Package Manager:**
- Nix package manager - Declarative package and configuration management
- Lockfile: `flake.lock` - Pinned flake dependencies (present and maintained)

## Frameworks

**Core System Configuration:**
- Flake-parts (hercules-ci/flake-parts) - Modular flake composition framework
- Home Manager (nix-community/home-manager v25.11) - User environment management
- NixOS Hardware (NixOS/nixos-hardware) - Hardware-specific configurations

**Desktop Environment:**
- GNOME (via desktopManager.gnome) - Primary desktop environment
- GDM - Display manager for GNOME
- X11 - Windowing system with German keyboard layout configuration

**Virtualisation:**
- Docker (rootless mode) - Container runtime with mirror registry fallback
- Podman - Alternative container runtime with docker-compose compatibility
- quickemu - VM management (available, not currently enabled)

**Testing/Development:**
- Flakes - Declarative dependency pinning and reproducible builds
- direnv - Per-project environment management with nix-direnv integration

**Build/Dev Tools:**
- treefmt-nix (numtide/treefmt-nix) - Multi-language code formatting
- nixfmt-classic - Nix code formatting (via treefmt)
- yamlfmt - YAML formatting (via treefmt)
- black - Python code formatting (via treefmt)

## Key Dependencies

**Critical Infrastructure:**
- nixos/nixpkgs/nixos-25.11 - Stable base packages and utilities
- nixos/nixpkgs/nixos-unstable - Cutting-edge versions of development tools
- nixos/nixpkgs (tailscale-specific commit) - Pinned version for Tailscale compatibility

**Nix Development Tools:**
- nix-output-monitor - Build output monitoring
- nix-tree - Dependency tree visualization
- nix-du - Nix store disk usage analysis
- nix-query-tree-viewer - Store visualization
- dconf2nix - GNOME settings conversion

**Container/Virtualisation:**
- dive - Docker image layer inspection
- podman-tui - Terminal UI for container management
- podman-desktop - Container management UI
- docker-compose - Container orchestration

**Networking & VPN:**
- tailscale - Mesh VPN (v25.11 from stable nixpkgs)
- networkmanager - Network management daemon

**Package Managers & Build Tools:**
- gcc - C compiler for native extensions
- gnumake - Build automation
- cmake - Cross-platform build system
- pkgconf - pkg-config replacement

**Programming Language Support:**
- golang - Go toolchain
- gopls - Go language server
- rustc/cargo - Rust toolchain
- rust-analyzer - Rust IDE support
- nodejs - JavaScript runtime
- pnpm/yarn - Alternative JavaScript package managers

## Configuration

**Environment:**
- System built via declarative NixOS configuration in `flake.nix`
- Machine-specific configs in `nixos/machines/{hostname}/`
- User environment managed via Home Manager in `nixos/users/djoolz.nix`
- Shared modules in `nixos/machines/common/`

**Build Configuration:**
- `flake.nix` - Primary flake definition with inputs management
- `outputs.nix` - Flake-parts output configuration
- `treefmt.nix` - Code formatting rules (excludes: *.gpg, *.pub, .git-crypt/*, etc.)

**Development Shells:**
- Per-system development shell with: nixpkgs-fmt, statix, deadnix
- Tools for Nix code analysis and formatting

**Nix Settings (in configurations.nix):**
- Experimental features: nix-command, flakes
- Extra substituters: nix-community.cachix.org, hetzner-cache.numtide.com
- Trust trusted-public-keys for cache verification
- Auto-optimise-store enabled for space efficiency
- Garbage collection: weekly, removes derivations older than 10 days
- GitHub PAT for nixpkgs access via `access-tokens` (in `nixos/configurations.nix`)

## Platform Requirements

**Development:**
- NixOS 24.11 or later (configured for 25.11)
- git for version control
- direnv integration for environment switching
- Flake support enabled in Nix daemon

**Production:**
- x86_64-linux: Desktop machines (Intel/AMD 64-bit)
- aarch64-linux: ARM 64-bit machines (e.g., Raspberry Pi 4)
- UEFI bootloader support (Intel + GRUB via centauri config)
- NetworkManager for wireless/wired connectivity

**Optional but Configured:**
- Docker daemon (rootless, with userland-proxy and experimental features)
- Podman for OCI container management
- Tailscale for VPN/mesh networking
- Flatpak runtime for containerized applications

---

*Stack analysis: 2026-02-04*
