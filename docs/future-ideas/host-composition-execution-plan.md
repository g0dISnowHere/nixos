# Host Composition Concrete Execution Plan

This plan turns the architecture refactor into ordered file work.

## Goal

Make `nixos/machines/<host>/default.nix` the canonical host definition, reduce `flake/` to orchestration, and remove role/UI shorthand from host and Home Manager composition.

## Phase 0 — Baseline and safety checks

### Files to inspect before edits

- `flake/lib.nix`
- `flake/machines/workstations.nix`
- `flake/machines/servers.nix`
- `nixos/machines/centauri/default.nix`
- `nixos/machines/mirach/default.nix`
- `nixos/machines/albaldah/default.nix`
- `nixos/machines/alhena/default.nix`
- `flake/homes/profiles/base.nix`
- `flake/homes/profiles/gui.nix`
- `flake/homes/users/djoolz/workstation.nix`
- `flake/homes/users/djoolz/server.nix`
- `flake/homes/users/djoolz/personal.nix`
- `flake/monitoring-inventory.nix`
- `flake/secrets-policy.nix`

### Baseline verification

Run before refactor and save outputs per host:

- `nix eval .#nixosConfigurations.centauri.config.networking.hostName`
- `nix eval .#nixosConfigurations.mirach.config.networking.hostName`
- `nix eval .#nixosConfigurations.albaldah.config.networking.hostName`
- `nix eval .#nixosConfigurations.alhena.config.networking.hostName`

Optional targeted follow-ups when a host changes:

- `nix eval .#nixosConfigurations.<host>.config.home-manager.users.djoolz.home.stateVersion`
- `nix eval .#nixosConfigurations.<host>.config.system.stateVersion`

## Phase 1 — Choose the canonical host composition shape

### Decision to implement

Put all host behavior selection in `nixos/machines/<host>/default.nix`.

### Files to change

- `flake/lib.nix`
- `flake/machines/workstations.nix`
- `flake/machines/servers.nix`
- all `nixos/machines/*/default.nix`

### Concrete edits

1. Change `flake/lib.nix` `mkNixosSystem` signature so it only needs:
   - `system`
   - `hostname`
   - `modules ? [ ]`
   - `extraSpecialArgs ? { }`

2. Remove from `mkNixosSystem`:
   - `desktopEnvironment ? null`
   - `enableHomeManager ? false`
   - `desktopEnvironmentModule`
   - `homeManagerModule`
   - Home Manager `extraSpecialArgs` wiring that depends on the toggle

3. Keep in `mkNixosSystem` only shared orchestration modules that are truly near-universal.

4. Move host capability imports from:
   - `flake/machines/workstations.nix`
   - `flake/machines/servers.nix`
   into each host default.

### First host to migrate

Start with `centauri`.

Why:

- already carries substantial canonical behavior
- exercises desktop and Home Manager paths
- will prove the hardest composition path first

## Phase 2 — Migrate `centauri` fully

### Files to change (Phase 2)

- `nixos/machines/centauri/default.nix`
- `flake/machines/workstations.nix`
- `flake/lib.nix`
- `flake/homes/users/djoolz/workstation.nix`
- `flake/homes/profiles/gui.nix`

### Concrete edits (Phase 2)

1. In `nixos/machines/centauri/default.nix`, add the imports currently supplied by `flake/machines/workstations.nix`:
   - `../../../modules/nixos/system/base.nix`
   - `../../../modules/nixos/system/powermanagement.nix`
   - `../../../modules/nixos/services/mosh.nix`
   - `../../../modules/nixos/services/tailscale-client.nix`
   - `../../../modules/nixos/virtualisation/docker.nix`
   - the inline `networking.networkmanager.enable = true` setting should move into the host file as normal config

2. Add explicit desktop/UI imports in the host instead of `desktopEnvironment = "gnome"`.
   - likely from `modules/nixos/desktop/gnome.nix`
   - keep desktop behavior visible in the host file

3. Add Home Manager integration explicitly in the host path instead of through `enableHomeManager = true`.
   - import `inputs.home-manager.nixosModules.home-manager` from the host or another explicit host-owned layer
   - move the Home Manager shared config block out of `mkNixosSystem` to an explicit reusable module if needed

4. Replace `home-manager.users.djoolz.imports = [ ../../../flake/homes/users/djoolz/workstation.nix ];`
   with either:
   - a new behavior-oriented HM module stack, or
   - direct explicit imports from the host

### Verification

- `nix eval .#nixosConfigurations.centauri.config.networking.hostName`
- `nix eval .#nixosConfigurations.centauri.config.home-manager.users.djoolz.home.stateVersion`
- `nix eval .#nixosConfigurations.centauri.config.services.displayManager.enable` or another concrete GNOME-related attr selected by the final implementation

## Phase 3 — Extract explicit Home Manager composition units

### Files to change (Phase 3)

- `flake/homes/profiles/base.nix`
- `flake/homes/profiles/gui.nix`
- `flake/homes/users/djoolz/workstation.nix`
- `flake/homes/users/djoolz/server.nix`
- maybe add new files under `flake/homes/users/djoolz/` or `modules/home/`

### Concrete edits (Phase 3)

1. Keep `base.nix` only for true minimum HM baseline.
2. Decompose `gui.nix` into explicit behavior modules.
   - remove `desktopEnvironment ? null`
   - remove DE conditionals
3. Replace role-named wrappers with behavior-named modules.

Candidate split:

- `flake/homes/users/djoolz/base.nix`
- `flake/homes/users/djoolz/gui-apps.nix`
- `flake/homes/users/djoolz/gnome.nix`
- `flake/homes/users/djoolz/niri.nix`
- retain `personal.nix`

4. Update each host HM import to use the new explicit stack.

### Verification (Phase 3)

For every touched host:

- `nix eval .#nixosConfigurations.<host>.config.home-manager.users.djoolz.home.stateVersion`

If standalone HM output remains:

- `nix eval .#homeConfigurations."djoolz@workstation".activationPackage.drvPath`

## Phase 4 — Migrate remaining hosts to canonical ownership

### Hosts

- `mirach`
- `albaldah`
- `alhena`

### Files to change per host

- `nixos/machines/<host>/default.nix`
- whichever inventory file still references it
- HM import path if changed

### Concrete edits (Phase 4)

#### `mirach`
Move in the modules currently chosen by `flake/machines/servers.nix`:

- `../../../modules/nixos/system/base.nix`
- `../../../modules/nixos/services/monitoring-baseline.nix`
- `../../../modules/nixos/services/vscode-remote.nix`
- `../../../modules/nixos/services/ssh-server.nix`
- `../../../modules/nixos/services/tailscale-router.nix`
- `../../../modules/nixos/virtualisation/docker.nix`
- `networking.networkmanager.enable = true`
- explicit GNOME imports replacing `desktopEnvironment`

#### `albaldah`
Move in the modules currently chosen by `flake/machines/servers.nix`:

- `../../../modules/nixos/system/base.nix`
- `../../../modules/nixos/services/monitoring-baseline.nix`
- `../../../modules/nixos/services/vscode-remote.nix`
- `../../../modules/nixos/services/crowdsec.nix`
- `../../../modules/nixos/services/tailscale-client.nix`
- `../../../modules/nixos/virtualisation/docker.nix`
- `inputs.disko.nixosModules.disko`
- `../../../modules/nixos/system/disko-install-test-compat.nix`
- keep `./disko.nix` in the host
- explicit Home Manager enablement in host composition

#### `alhena`
Move in the modules currently chosen by `flake/machines/servers.nix`:

- `../../../modules/nixos/system/base.nix`
- `../../../modules/nixos/system/wsl.nix` if still needed beyond host-local WSL import strategy
- `../../../modules/nixos/services/monitoring-baseline.nix`
- `../../../modules/nixos/services/vscode-remote.nix`
- `../../../modules/nixos/services/ssh-server.nix`
- `../../../modules/nixos/services/tailscale-client.nix`
- `../../../modules/nixos/virtualisation/docker.nix`
- explicit Home Manager enablement in host composition

### Verification (Phase 4)

After each host:

- `nix eval .#nixosConfigurations.<host>.config.networking.hostName`
- `nix eval .#nixosConfigurations.<host>.config.system.stateVersion`
- targeted host-specific attrs for moved features

## Phase 5 — Collapse inventory registration

### Files to change (Phase 5)

- `flake/machines/workstations.nix`
- `flake/machines/servers.nix`
- possibly `flake.nix` or another top-level flake aggregator file if registry shape changes

### Concrete edits (Phase 5)

Choose one:

1. delete role-based inventory files and replace them with one thin registry file
2. keep inventory files but make them registration-only

Registration-only means each host entry does no more than:

- call `self.lib.mkNixosSystem`
- pass `system`
- pass `hostname`
- pass any truly non-behavioral extra args still required

### Verification (Phase 5)

- all four `nix eval .#nixosConfigurations.<host>.config.networking.hostName` checks pass

## Phase 6 — Clean secondary taxonomies

### Files to change (Phase 6)

- `flake/monitoring-inventory.nix`
- `flake/secrets-policy.nix`

### Concrete edits (Phase 6)

1. In `flake/monitoring-inventory.nix`:
   - replace `host_role` naming if it implies architecture
   - keep `exposure_tier`, `service_roles`, `capabilities`, `monitoring_enabled`
   - rename group labels away from `workstations`, `local_servers`, `vps_hosts` if the names still imply behavior ownership

2. In `flake/secrets-policy.nix`:
   - replace `class` naming if it implies architectural role
   - keep grouping only if it reflects operational secret-distribution policy

### Verification (Phase 6)

- `nix eval` the inventory/secrets attrs you changed
- final `nix flake check`

## Phase 7 — Audit baselines for hidden policy

### Files to inspect and likely change

- `modules/nixos/system/base.nix`
- `modules/nixos/desktop/common.nix`
- `flake/homes/profiles/base.nix`

### Concrete edits (Phase 7)

- remove optional behavior that should be explicit at host or capability level
- keep only minimum valid shared baseline

### Verification (Phase 7)

- targeted `nix eval` for any host that depended on moved defaults
- final `nix flake check`

## Completion criteria

- each host’s behavior is readable from `nixos/machines/<host>/default.nix`
- `mkNixosSystem` no longer decides UI or Home Manager enablement
- role-named HM wrappers are gone or replaced by behavior names
- inventory files no longer own behavior
- metadata taxonomies no longer conflict with the host model
- targeted host evals pass
- `nix flake check` passes
