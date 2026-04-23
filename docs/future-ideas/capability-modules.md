# Capability Modules Instead Of Fuzzy Machine Roles

The current broad role labels such as `workstation` and `homelab` are starting
to hide too many different concerns behind one word.

## Problem

Several machines no longer fit neatly into a single role:

- `centauri`
  - personal workstation
  - GNOME desktop
  - rootless Docker
- `mirach`
  - server-style machine
  - GNOME desktop for local management
  - libvirt
  - normal Docker
- `karaka`
  - simple media station
  - GNOME desktop
  - normal Docker for a few containers
- `albaldah`
  - headless VPS
  - normal Docker
- `alhena`
  - server-like WSL environment
  - close to `albaldah`, but with WSL platform constraints

`homelab` especially is doing too much at once. It currently implies some mix
of:

- SSH server policy
- Tailscale behavior
- Docker usage
- optional GUI
- a rough machine intent

That makes the label too fuzzy to be a reliable architecture boundary.

## Direction

Prefer capability modules over large semantic roles.

Examples of capabilities:

- `gnome`
- `docker`
- `docker_rootless`
- `libvirtd`
- `media-station`
- `ssh-server`
- `tailscale-client`
- `tailscale-router`
- `scanner`
- `flatpak`

Flatpak should follow the same pattern:

- one small system capability for Flatpak infrastructure
- separate focused modules for groups of Flatpak applications
- optional bundles only when a repeated machine intent becomes clear

Example layout:

- `modules/nixos/services/flatpak.nix`
  - enable Flatpak support, remotes, and portal/system integration
- `modules/nixos/flatpak/browsers.nix`
- `modules/nixos/flatpak/media.nix`
- `modules/nixos/flatpak/creative.nix`
- `modules/nixos/flatpak/messaging.nix`
- `modules/nixos/flatpak/bundles/media-station.nix`
  - only if this avoids repeating the same imports across multiple machines

Keep Flatpak infrastructure separate from application bundles. A machine should
be able to enable Flatpak support without automatically inheriting a personal
desktop app set, and a headless host should not receive Flatpaks just because it
shares another server capability.

The machine definition should describe what the machine actually does instead of
forcing it into one overloaded role name.

## Possible Shape

Keep machine composition explicit and additive:

- a small structural base for things that are truly shared
- host-local configuration for hardware and machine-specific overrides
- capability modules for behavior

That would make machine intent easier to read:

- `karaka` = GNOME + media-station + Docker
- `mirach` = SSH server + Tailscale router + GNOME + libvirtd + Docker
- `centauri` = GNOME + scanner + Docker rootless

Flatpaks would compose in the same explicit way:

- `karaka` = Flatpak infrastructure + media Flatpaks
- `centauri` = Flatpak infrastructure + browser, messaging, and creative Flatpaks
- `albaldah` = no Flatpak modules
- `alhena` = no Flatpak modules

Concrete composition should stay boring and readable. Prefer explicit imports
over a second layer of clever discovery:

```nix
imports = [
  ../../modules/nixos/desktop/gnome.nix
  ../../modules/nixos/services/ssh.nix
  ../../modules/nixos/services/tailscale-router.nix
  ../../modules/nixos/services/flatpak.nix
  ../../modules/nixos/flatpak/media.nix
  ../../modules/nixos/virtualisation/docker.nix
];
```

Some capabilities should also assert invalid combinations. For example,
`docker` and `docker_rootless` should not silently coexist; the Docker modules
now carry internal markers that fail evaluation if both are imported.
`tailscale-client` versus `tailscale-router` should make routing and firewall
behavior explicit.

## Migration Idea

Do this gradually instead of as one large refactor:

1. Keep the current machine set files for orchestration.
2. Move behavior out of broad role modules into focused capability modules.
3. Remove role modules when explicit capability imports make them unnecessary.
4. Introduce one or two machine-intent modules only where the concept stays
   crisp and useful.
5. Keep `mkNixosSystem` as orchestration only; it should not import broad role
   policy by name.

Start with `homelab`, because it currently covers hosts with very different
needs. `mirach`, `albaldah`, and `alhena` can all be server-like without
sharing desktop, Docker, Tailscale routing, or Flatpak behavior by implication.
`alhena` should stay close to `albaldah` in intent, with a WSL platform module
for the differences that come from running under Windows.

## Outcome

This would make the repo easier to reason about because machine behavior would
be assembled from explicit capabilities instead of inferred from role names that
mean different things on different hosts.
