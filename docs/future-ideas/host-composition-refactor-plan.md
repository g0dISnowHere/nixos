# Host Composition Refactor Plan

## Problem

Current host meaning is split across:

- `flake/machines/{workstations,servers}.nix`
- `flake/lib.nix`
- `nixos/machines/<host>/default.nix`
- `flake/homes/users/djoolz/{workstation,server}.nix`

Grounding:

- `flake/lib.nix` injects `../nixos/machines/${hostname}`, optional `desktopEnvironment`, optional Home Manager, and shared user/system modules.
- `flake/machines/workstations.nix` and `servers.nix` still choose per-host module lists and set `desktopEnvironment` / `enableHomeManager`.
- `nixos/machines/*/default.nix` already carry host-local imports, Home Manager user imports, and `system.stateVersion`.
- `flake/homes/profiles/gui.nix` and `flake/homes/users/djoolz/workstation.nix` / `server.nix` preserve role/UI shorthand.
- `flake/monitoring-inventory.nix` and `flake/secrets-policy.nix` still encode host roles/classes.

## Target

- `nixos/machines/<host>/default.nix` = canonical host definition
- `flake/` = registration/orchestration only
- no role-owned behavior
- no leaky `desktopEnvironment` switch
- Home Manager explicit per host
- UI stacks expressed as explicit imports/capabilities

## Phased plan

### Phase 1 — Freeze vocabulary and boundaries

Use `CONTEXT.md` as the refactor gate.

Rules:

- reject new role language in code comments, profiles, helpers
- reject new behavior in inventory/grouping files
- reject new shorthand that hides capability imports

Deliverable:

- refactor uses `Host Setup`, `Capability Module`, `Canonical Host Definition`, `User Environment`, `Linked Dotfiles`

### Phase 2 — Make host defaults the only behavioral entrypoint

Move per-host behavior selection out of `flake/machines/*.nix` into `nixos/machines/<host>/default.nix`.

Concrete changes:

- each host default imports its own capability modules explicitly
- each host default decides whether Home Manager is enabled
- each host default decides its UI stack explicitly
- keep host-local files there: hardware, firewall, provider/network quirks, disk layout, stateVersion

After this phase:

- `flake/machines/*.nix` should stop choosing capabilities

### Phase 3 — Shrink `mkNixosSystem` to orchestration

Refactor `flake/lib.nix` `mkNixosSystem` so it stops owning host meaning.

Remove from `mkNixosSystem`:

- `desktopEnvironment ? null`
- `enableHomeManager ? false`
- implicit desktop module injection
- implicit Home Manager integration toggle tied to host registration

Keep in `mkNixosSystem`:

- `system`
- `hostname`
- shared flake inputs/helpers
- truly global modules only, if they are valid for nearly every host

Decision test for every module still injected globally:

- would a plausible future host reject this? If yes, it does not belong there.

### Phase 4 — Collapse inventory files into registration only

Refactor `flake/machines/{workstations,servers}.nix`.

Options:

- remove them and register hosts directly from `nixos/machines/`
- or keep them as thin inventory indexes only

But in either case:

- no per-host capability lists
- no `desktopEnvironment`
- no `enableHomeManager`
- no pseudo-role comments driving architecture

Best end state is likely one thin host registry file or one registry per technical concern, not per role label.

### Phase 5 — Replace role-named Home Manager wrappers

Current smell:

- `flake/homes/users/djoolz/workstation.nix`
- `flake/homes/users/djoolz/server.nix`
- `flake/homes/profiles/gui.nix`

Refactor:

- replace role/profile wrappers with capability-oriented or explicit composition units
- host Home Manager imports should read like behavior, not class

Examples of acceptable direction:

- `homes/users/djoolz/base.nix`
- `homes/users/djoolz/gui-apps.nix`
- `homes/users/djoolz/niri.nix`
- or host-owned Home Manager composition directly from `nixos/machines/<host>/default.nix`

Avoid:

- `workstation`
- `server`
- opaque GUI switch wrappers

### Phase 6 — Decompose UI shorthand

Replace `desktopEnvironment = "gnome"` style switching with explicit imports.

Target:

- GNOME/Niri/etc. become visible capability composition
- if a helper survives, it must be a thin macro whose expansion is obvious

Likely work:

- move DE-specific imports out of conditionals
- import GNOME/Niri-related modules explicitly per host or per Home Manager composition layer

### Phase 7 — Clean up secondary role/class taxonomies

After canonical host ownership is fixed, align metadata layers.

Targets:

- `flake/monitoring-inventory.nix`
- `flake/secrets-policy.nix`

Refactor intent:

- replace `host_role` / `class = "workstation"` / `local_server` / `vps` where they imply architecture
- keep metadata that serves operations, but name it operationally:
  - exposure tier
  - service roles
  - monitoring enabled
  - secret recipients
- only keep grouped labels when they are inventory/reporting metadata, not behavior selectors

`secrets-policy.nix` may still need a grouping for key distribution, but it should be renamed if it currently suggests architectural ownership.

### Phase 8 — Tighten shared baseline layers

Audit these for hidden policy:

- `modules/nixos/system/base.nix`
- `modules/nixos/desktop/common.nix`
- `flake/homes/profiles/base.nix`

Rule:

- `base` means minimum valid baseline only
- anything optional or host-selective moves outward into explicit imports

## Suggested execution order

Smallest safe order:

1. pick one host as pilot: `centauri` or `albaldah`
2. move that host’s capability/UI/Home Manager choices into `nixos/machines/<host>/default.nix`
3. reduce `mkNixosSystem` enough to support that host
4. convert Home Manager wrapper naming for that host
5. verify
6. repeat for remaining hosts
7. collapse inventory files
8. clean metadata taxonomies
9. audit residual `base` layers

Why this order:

- proves the model on one host
- reduces blast radius
- avoids big-bang failure in `flake/lib.nix`

## Verification

Per repo guidance: prefer targeted `nix eval`; use broader checks later.

For each migrated host:

- verify the host output still evaluates:
  - `nix eval .#nixosConfigurations.<host>.config.networking.hostName`
- verify critical booleans/paths affected by the move
- if Home Manager attachment changes, verify the Home Manager subtree evaluates through the NixOS config path
- if standalone Home Manager outputs are retained, verify the relevant `homeConfigurations` output too

After each phase:

- `nix flake check` once the phase leaves the tree in a coherent state

Do not rely on only one global check during the whole migration.

## Main risks

1. **False cutover**
   - behavior appears moved, but `mkNixosSystem` still injects it implicitly

2. **Role renaming without architectural change**
   - `workstation/server` disappear from filenames, but hidden grouping behavior remains

3. **UI decomposition regression**
   - GNOME/Niri support breaks because shorthand carried more behavior than expected

4. **Home Manager duplication**
   - host default and Home Manager wrapper both own the same decision during transition

5. **Operational metadata drift**
   - monitoring/secrets metadata keeps old taxonomy after host model changes

## Done criteria

Plan is complete when:

- every host has one canonical definition under `nixos/machines/<host>/default.nix`
- `flake/` only exposes/orchestrates hosts
- no inventory file selects host behavior
- no leaky `desktopEnvironment` switch remains
- role-named Home Manager wrappers are gone or reduced to clearly behavioral names
- targeted `nix eval` passes for each touched host
- `nix flake check` passes at the end
