# External Integrations

**Analysis Date:** 2026-02-04

## APIs & External Services

**GitHub:**
- Purpose: Flake dependency source and package repository access
- SDK/Client: `gh` (GitHub CLI) installed from nixpkgs-unstable
- Auth: GitHub PAT stored in `nixos/configurations.nix` under `nix.settings.access-tokens`
- Reference: `github.com` access-token configured for Nix flake operations

**Package Caches & Substituters:**
- nix-community.cachix.org - Community package cache for faster builds
- hetzner-cache.numtide.com - Hetzner-hosted cache for additional packages
- docker registry mirrors - GCR (gcr.io) mirror fallback for Docker

## Data Storage

**Databases:**
- Not used - This is a declarative configuration repository, not an application with persistent data

**File Storage:**
- Local filesystem only - Configuration stored in git repository (`/home/djoolz/Documents/01_config/mine`)
- User home directory: `/home/djoolz/` - Managed by Home Manager
- Syncthing: Peer-to-peer file synchronization service enabled (`services.syncthing.enable = true` in `nixos/users/djoolz.nix`)

**Caching:**
- Nix store caching via binary cache substituters
- Flatpak package cache with weekly auto-updates
- Docker image cache with automatic weekly pruning
- Podman image cache with automatic daily updates

## Authentication & Identity

**Nix/Flake Authentication:**
- GitHub PAT via `access-tokens` in `nix.settings` (`nixos/configurations.nix`, line 42-44)
- Trusted users: `djoolz` group configured in `nix.settings.trusted-users`

**System Authentication:**
- User: `djoolz` (normal user with sudo wheel access)
- Groups: networkmanager, wheel, docker, wireshark, libvirtd, plugdev
- SSH integration potentially available via home-manager direnv

## Monitoring & Observability

**Error Tracking:**
- None detected - Configuration system doesn't include dedicated error tracking

**Logs:**
- systemd journal - Standard NixOS/Linux logging
- Service logs available via `journalctl`
- Container logs: Docker and Podman via respective CLIs

## CI/CD & Deployment

**Hosting:**
- Local machine deployment - NixOS systems deployed via `nixos-rebuild switch --flake`
- Multi-machine support: `centauri` and `mirach` configurations defined
- Flake-based reproducible builds

**CI Pipeline:**
- None configured - This is a configuration repository, not an application
- Code formatting via `treefmt` (nixfmt-classic, yamlfmt, black)
- Optional automatic garbage collection: `nix.gc.automatic = true` (weekly)

**Package Building:**
- Nix flakes for reproducible builds
- GitHub Actions could be integrated (infrastructure not currently present)

## Environment Configuration

**Required Environment Variables:**
- `GOPATH=$HOME/go` - Go workspace
- `GOBIN=$HOME/go/bin` - Go binary output
- `NPM_CONFIG_PREFIX=$HOME/.npm-global` - npm global prefix
- `CARGO_HOME=$HOME/.cargo` - Rust cargo home

**Path Configuration (in shell.init):**
- `$HOME/go/bin` - Go binaries
- `$HOME/.npm-global/bin` - npm global packages
- `$HOME/.cargo/bin` - Rust/cargo binaries
- `$HOME/.local/bin` - Python pipx packages

**Secrets Location:**
- GitHub PAT: `nixos/configurations.nix` line 42-44 (in access-tokens array)
  - **WARNING:** This is a sensitive credential stored in version-controlled Nix files
  - Should be migrated to encrypted secrets (commented sops-nix is available but not enabled)

**Optional Environment Variables (commented out):**
- `PIP_BREAK_SYSTEM_PACKAGES` - Allow global pip installs (security consideration)
- `PIP_TARGET` / `PIP_PREFIX` - Python package installation targets

## Webhooks & Callbacks

**Incoming:**
- None detected - Configuration system doesn't expose HTTP endpoints

**Outgoing:**
- Flatpak repositories: Update notifications from flathub.org (auto-updates weekly)
- Docker registry mirrors: Pull requests to gcr.io and Docker Hub
- GitHub flake inputs: Version checks via `flake update` command

## Service Integrations

**Desktop Integration:**
- KDE Connect (disabled) - Available but not enabled
- GNOME Extensions - Supported via `org.gnome.Extensions` flatpak
- Touchegg - Multi-touch gesture support enabled

**Containerization Services:**
- Docker rootless daemon with experimental features and registry mirrors
- Podman with default DNS resolution and docker-compose compatibility
- Both services set to auto-prune images weekly/daily

**Device Management:**
- ratbagd - Input device configuration (mice, etc.)
- spice-vdagentd - VM guest additions support
- NetworkManager - Wireless and wired network management

**File Synchronization:**
- Syncthing enabled in home-manager for peer-to-peer file sync
- Nextcloud Client available (installed, optional)
- Synology Drive Client available (installed, optional)

**Remote Access:**
- Tailscale VPN configured with UDP port 41641 allowed
- RustDesk available (flatpak) for remote desktop
- FreeRDP available (flatpak) for RDP connections
- Moonlight-qt for game streaming

## Third-Party Applications (via Flatpak)

**Productivity & Collaboration:**
- Spotify - Music streaming
- Signal - Secure messaging
- Thunderbird - Email client
- Firefox - Web browser via flatpak

**Development Tools:**
- DBeaver Community - Database UI
- MQTT5 Explorer - IoT debugging
- DBeaverCommunity - Data exploration

**Media & Design:**
- Blender - 3D modeling
- Krita/Illustrator alternatives
- OrcaSlicer - 3D print slicing
- Refine (formerly OpenRefine) - Data cleaning

**Utilities:**
- Flatseal - Flatpak permission manager
- Warehouse - Flatpak package browser
- FlatSweep - Flatpak cleanup tool

---

*Integration audit: 2026-02-04*

## Security Notes

**Exposed Credentials:**
- GitHub PAT visible in `nixos/configurations.nix` (line 42-44) - This is a security risk
  - Recommended: Implement sops-nix (infrastructure commented out in flake.nix)
  - Alternative: Move to encrypted dotenv or secrets management service

**Network Exposure:**
- Syncthing: Service reachable via network (mentioned in comment as needing open firewall port)
- Docker: Rootless mode mitigates privilege escalation
- Tailscale: UDP 41641 deliberately opened for VPN mesh connectivity

**Container Registry:**
- GCR mirror fallback provides single point of failure for image pulls
- Consider adding additional registry mirrors or fallbacks
