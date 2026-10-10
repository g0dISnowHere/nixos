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
  Its WSL environment cannot register the audit daemon PID, so the host disables
  kernel audit configuration, `auditd`, and journald's audit subscription.
  Ordinary journald logging and monitoring remain enabled; they do not replace
  security audit events.
  Windows executable interop reuses WSL's existing binfmt handler; NixOS does
  not register another handler in WSL's protected registry.

## Module Boundaries

- `modules/nixos/system/`: platform and baseline system behavior like
  `base.nix`, WSL support, Nix settings, shell integration, secrets plumbing
- `modules/nixos/services/`: reusable service capabilities like SSH server,
  Tailscale client/router, Flatpak infra, scanner, firewall, audio, Bluetooth,
  printing, service discovery, and other service modules
- `modules/nixos/virtualisation/`: container and virtualization capabilities
  like Docker, rootless Docker, podman, quickemu
- `modules/nixos/desktop/`: desktop environment and desktop infra modules
- `modules/nixos/flatpak/`: focused Flatpak app sets; infra stays in
  `modules/nixos/services/flatpak.nix`

## Composition

`flake/lib.nix` provides `mkNixosSystem` as orchestration helper. It wires
shared flake inputs, SOPS support, Nix daemon settings, default user plumbing,
and imports the canonical host definition. Host files now own Home Manager,
desktop, and capability selection explicitly.

Machine inventory files under `flake/machines/` register hosts for navigation
and output exposure. They do not choose host behavior.

## Guardrails

Capabilities should fail early on bad combinations. Docker uses internal
markers so importing both `docker.nix` and `docker_rootless.nix` fails during
eval.

Flatpak infra and Flatpak app sets stay separate. Host can enable Flatpak
without inheriting personal desktop bundle. Headless hosts should not get
Flatpaks through unrelated server behavior.
Mirach and Karaka retain GNOME for local administration but omit consumer GNOME
apps, GNOME Software, the GUI IDE bundle, and all Flatpak application packages.
The `gnome-local-admin.nix` capability keeps core administration tools while
excluding browser, media, communications, scanning, and other non-admin apps.
Mirach uses `flake/homes/users/djoolz/mirach.nix`, which retains its original
CLI packages (`esptool`, `libnotify`, `parted`, `syncthing`, and
`wl-clipboard`) and replaces GUI `wireshark` with CLI-only `wireshark-cli`,
retaining `tshark` and `dumpcap`, alongside fonts and keyring backup. Karaka
retains its existing base user profile and Syncthing CLI. Both keep
`developer-tools.nix`. Workstation profiles and their GUI application bundles
remain unchanged.


## Home Manager Boundary

Home Manager stays user-environment layer. NixOS capability modules choose
system behavior. Home Manager profiles and modules choose user packages,
services, settings, dotfile links.
