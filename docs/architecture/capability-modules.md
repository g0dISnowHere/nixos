# Capability Modules

Machine behavior is assembled from explicit capability modules rather than broad
machine role modules.

## Core Rule

A machine definition should show what the host actually does. Prefer a readable
list of imports over an abstract label that hides SSH, Tailscale, Docker,
desktop, or Flatpak policy.

Examples:

- `centauri` imports base system behavior, laptop power management, GNOME,
  Tailscale client behavior, and rootless Docker.
- `mirach` imports base system behavior, SSH server behavior, Tailscale router
  behavior, GNOME for local management, and rootful Docker.
- `albaldah` imports base system behavior, SSH server behavior, Tailscale router
  behavior, rootful Docker, and VPS disk/network specifics.
- `alhena` imports base system behavior, WSL platform behavior, SSH server
  behavior, Tailscale client behavior, and Docker.

## Module Boundaries

- `modules/nixos/system/`
  - platform and baseline system behavior such as `base.nix`, WSL support, Nix
    settings, shell integration, and secrets plumbing
- `modules/nixos/services/`
  - reusable service capabilities such as SSH server, Tailscale client/router,
    Flatpak infrastructure, scanner, firewall, and service-specific modules
- `modules/nixos/virtualisation/`
  - container and virtualization capabilities such as Docker, rootless Docker,
    podman, and quickemu
- `modules/nixos/desktop/`
  - desktop environment and desktop infrastructure modules
- `modules/nixos/flatpak/`
  - focused Flatpak application sets; Flatpak infrastructure stays in
    `modules/nixos/services/flatpak.nix`

## Composition

`flake/lib.nix` provides `mkNixosSystem` as an orchestration helper. It wires
shared flake inputs, Home Manager integration, desktop selection, SOPS support,
Nix daemon settings, and the default user plumbing. It does not import machine
roles by name.

Machine sets under `flake/machines/` choose concrete capabilities explicitly:

- `workstations.nix` contains local workstation-style hosts.
- `servers.nix` contains server-like hosts, including VPS and WSL hosts.

## Guardrails

Capabilities should fail early for invalid combinations. Docker uses internal
markers so importing both `docker.nix` and `docker_rootless.nix` fails during
evaluation.

Flatpak infrastructure and Flatpak application sets stay separate. A host can
enable Flatpak without inheriting a personal desktop application bundle, and
headless hosts should not receive Flatpaks through unrelated server behavior.

## Home Manager Boundary

Home Manager remains the user-environment layer. NixOS capability modules choose
system behavior; Home Manager profiles and modules choose user packages,
services, settings, and dotfile links.
