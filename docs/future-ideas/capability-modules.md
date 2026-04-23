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
  - WSL environment

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

## Migration Idea

Do this gradually instead of as one large refactor:

1. Keep the current machine set files for orchestration.
2. Move behavior out of broad role modules into focused capability modules.
3. Reduce role modules to small structural defaults, or remove them if they stop
   carrying their weight.
4. Introduce one or two machine-intent modules only where the concept stays
   crisp and useful.

## Outcome

This would make the repo easier to reason about because machine behavior would
be assembled from explicit capabilities instead of inferred from role names that
mean different things on different hosts.
