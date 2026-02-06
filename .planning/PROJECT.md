# NixOS Configuration with Secrets Management

## What This Is

A modular NixOS flake configuration managing two machines (centauri and mirach) with ragenix-based secrets management for secure credential handling and remote deployment capability.

## Core Value

Secrets are encrypted in version control and automatically decrypted on system activation, eliminating hardcoded credentials while maintaining reproducible builds.

## Requirements

### Validated

- ✓ Multi-machine NixOS configuration (centauri, mirach) — existing
- ✓ Flake-based modular system with flake-parts — existing
- ✓ Home-manager for user environment management — existing
- ✓ GNOME desktop environment with dconf settings — existing
- ✓ Docker/Podman containerization support — existing
- ✓ Development tooling (Go, Rust, Python, Node.js) — existing
- ✓ Auto-formatting with treefmt (Nix, YAML, Python) — existing
- ✓ Tailscale VPN integration — existing
- ✓ System factory pattern via mkNixosSystem — existing

### Active

- [ ] Ragenix flake input and NixOS module integration
- [ ] SSH service enabled on both machines (generates host keys)
- [ ] GitHub PAT encrypted and deployed to both machines
- [ ] Personal SSH key encrypted and deployed to both machines
- [ ] Centauri→mirach SSH key encrypted and deployed to centauri only
- [ ] Replace hardcoded GitHub token in nixos/configurations.nix with ragenix reference
- [ ] SSH keys deployed to appropriate locations (~/.ssh/)
- [ ] Remote deployment capability from centauri to mirach via SSH
- [ ] Age encryption configuration with both machines' host keys
- [ ] Secret files committed to repo in encrypted form

### Out of Scope

- Remote builds (using mirach as build machine for centauri) — each machine builds its own config locally
- User password management via ragenix — deferred to future
- Additional secrets beyond GitHub PAT and SSH keys — not needed now
- Automated key rotation — manual rotation acceptable for v1

## Context

**Security Issue:**
Currently a GitHub personal access token is hardcoded in `nixos/configurations.nix` lines 42-44. This token is exposed in version control and must be rotated and replaced with encrypted storage immediately.

**Technical Environment:**
- NixOS 25.11 stable with flake-parts architecture
- Two x86_64-linux machines: centauri (current host), mirach (remote)
- Existing SSH infrastructure not yet configured
- Git repo tracking all configuration

**Deployment Pattern:**
User manages both machines from centauri, deploying mirach's configuration remotely via SSH. Each machine builds its own configuration locally (no remote build offloading).

**Ragenix Choice:**
Using ragenix (Rust implementation) instead of agenix for better CLI, validation, and compatibility while maintaining drop-in replacement status.

## Constraints

- **Compatibility**: Must integrate with existing flake structure without breaking current builds
- **NixOS Module System**: Secrets must be accessible via standard NixOS options (age.secrets.*)
- **SSH Key Infrastructure**: Uses existing SSH key paradigm (host keys + personal keys)
- **Version Control**: Encrypted secrets committed to repo, plaintext secrets never committed
- **Multi-Machine**: Same flake must support both centauri and mirach with different decryption capabilities
- **Build Reproducibility**: Secret decryption happens at activation time, not build time

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Ragenix over agenix | Rust implementation with better CLI and validation, drop-in compatible | — Pending |
| Age encryption with SSH keys | Leverages existing SSH infrastructure, no new key management | — Pending |
| Secrets in /run/agenix/ | Standard ragenix pattern, tmpfs mount for security | — Pending |
| Per-machine host key encryption | Each machine can only decrypt its own secrets | — Pending |

---
*Last updated: 2026-02-06 after initialization*
