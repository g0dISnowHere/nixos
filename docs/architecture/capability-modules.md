# Capability Modules

Machine behavior built from explicit capability modules, not broad role
modules.

## Core Rule

Machine definition should show what host actually does. Prefer readable import
list over abstract label hiding SSH, Tailscale, Docker, desktop, Flatpak
policy.

Examples:

- `centauri` imports base system behavior, laptop power management, GNOME,
  Tailscale client behavior, and rootless Docker.
- `mirach` imports base system behavior, SSH server behavior, Tailscale router
  behavior, GNOME for local management, and rootful Docker.
- `albaldah` imports base system behavior, VS Code remote-session support,
  CrowdSec, Tailscale router behavior, rootful Docker, and VPS disk/network
  specifics. Remote administration is intended to use Tailscale SSH rather
  than a public OpenSSH listener.
- `alhena` imports base system behavior, WSL platform behavior, SSH server
  behavior, Tailscale client behavior, and Docker.

## Module Boundaries

- `modules/nixos/system/`: platform and baseline system behavior like
  `base.nix`, WSL support, Nix settings, shell integration, secrets plumbing
- `modules/nixos/services/`: reusable service capabilities like SSH server,
  Tailscale client/router, Flatpak infra, scanner, firewall, service modules
- `modules/nixos/virtualisation/`: container and virtualization capabilities
  like Docker, rootless Docker, podman, quickemu
- `modules/nixos/desktop/`: desktop environment and desktop infra modules
- `modules/nixos/flatpak/`: focused Flatpak app sets; infra stays in
  `modules/nixos/services/flatpak.nix`

## Composition

`flake/lib.nix` provides `mkNixosSystem` as orchestration helper. It wires
shared flake inputs, Home Manager integration, desktop selection, SOPS support,
Nix daemon settings, default user plumbing. It does not import machine roles by
name.

Machine sets under `flake/machines/` choose concrete capabilities explicitly:

- `workstations.nix` contains local workstation-style hosts
- `servers.nix` contains server-like hosts, including VPS and WSL hosts

## Guardrails

Capabilities should fail early on bad combinations. Docker uses internal
markers so importing both `docker.nix` and `docker_rootless.nix` fails during
eval.

Flatpak infra and Flatpak app sets stay separate. Host can enable Flatpak
without inheriting personal desktop bundle. Headless hosts should not get
Flatpaks through unrelated server behavior.

## Home Manager Boundary

Home Manager stays user-environment layer. NixOS capability modules choose
system behavior. Home Manager profiles and modules choose user packages,
services, settings, dotfile links.
