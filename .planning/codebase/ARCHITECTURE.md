# Architecture

**Analysis Date:** 2026-02-04

## Pattern Overview

**Overall:** Modular NixOS flake-based configuration with layered system and home-manager user setup.

**Key Characteristics:**
- Flake-driven configuration using `flake.nix` as entry point
- Multi-machine support with individual hardware/configuration profiles
- Separation of concerns: system-level (NixOS), user-level (home-manager), and common shared modules
- Module composition via explicit imports - configuration accumulates through module imports
- Per-system package overlays (nixpkgs, nixpkgs-unstable, nixpkgs-tailscale)
- Parameterized system factory pattern using `mkNixosSystem` helper

## Layers

**Flake Output Layer:**
- Purpose: Orchestrate the entire system build and define available configurations
- Location: `outputs.nix`, `flake.nix`
- Contains: System factory function, flake outputs definition, per-system dev shells
- Depends on: nixpkgs, home-manager, nix-flatpak, nixpkgs-unstable, treefmt-nix
- Used by: `nix flake` commands; `nixos-rebuild` references flake outputs

**Machine Configuration Layer:**
- Purpose: Define system-level settings per machine (bootloader, services, hardware)
- Location: `nixos/machines/{hostname}/`
- Contains: `default.nix` (aggregates imports), `configuration.nix` (main config), hardware files, optional networking/firewall/bootloader configs
- Depends on: Common modules, hardware configurations, nixos modules
- Used by: System factory in configurations.nix

**Common Modules Layer:**
- Purpose: Shared NixOS modules across all machines
- Location: `nixos/machines/common/`
- Contains: Desktop environment (GNOME/KDE), services (Tailscale, Flatpak), virtualisation (Docker, Podman, Libvirtd), shell setup, autoupgrade, power management
- Depends on: nixpkgs packages, NixOS module system
- Used by: Individual machine configurations via imports

**User Configuration Layer:**
- Purpose: Per-user settings managed by home-manager
- Location: `nixos/users/`
- Contains: `djoolz.nix` (main user config), `modules/` subdirectory with packages, programs, dconf, flatpak, homeassistant
- Depends on: home-manager, nixpkgs, nixpkgs-unstable
- Used by: System factory in configurations.nix (imported under home-manager.users.djoolz)

**Package & Program Modules Layer:**
- Purpose: Organize home-manager packages and program configurations
- Location: `nixos/users/modules/{packages,programs,dconf,flatpak}.nix`
- Contains: User packages list, CLI tools, development toolchains, program settings, dconf database settings
- Depends on: pkgs (from home-manager context)
- Used by: Main user configuration (`nixos/users/djoolz.nix`)

## Data Flow

**System Initialization Flow:**

1. User runs `nixos-rebuild switch --flake .#centauri`
2. `flake.nix` defines inputs (nixpkgs, home-manager, nix-flatpak, etc.)
3. `outputs.nix` is evaluated via `flake.nix` line 43: `outputs = { self, ... }@args: import ./outputs.nix args;`
4. `outputs.nix` calls `nixos/configurations.nix` (line 47) which applies `mkNixosSystem`
5. `mkNixosSystem` combines:
   - Machine-specific `nixos/machines/{hostname}/default.nix` (which imports sub-configs)
   - Common modules via machine imports
   - Home-manager module wrapping `nixos/users/djoolz.nix`
   - Nix daemon settings and cache configuration
6. Home-manager unpacks its nested imports: packages.nix, programs.nix, dconf.nix, flatpak.nix
7. All imports are merged into a single attribute set
8. NixOS evaluates this set and builds the system derivation
9. `nixos-rebuild` applies changes to the running system

**Configuration Composition Order:**

Machine `default.nix` imports are processed first (hardware-configuration → actual imports list), then system config is layered on top. For machines with explicit machine-level imports (like centauri), those files get merged into the NixOS module list before home-manager is processed.

**State Management:**

- **Immutable configuration state:** All configuration is expressed as Nix attributes; no runtime state in config files
- **System package state:** Managed by Nix store (`/nix/store`) with garbage collection enabled (10-day retention in `nixos/machines/common/autoupgrade.nix`)
- **User package state:** Home-manager manages user profiles under home.packages
- **Service state:** Services (Tailscale, Flatpak, etc.) maintain runtime state in `/var` or user home directories, but service *definitions* are immutable Nix expressions
- **Git tracking:** flake.lock tracks exact input revisions, ensuring reproducible builds

## Key Abstractions

**mkNixosSystem Factory:**
- Purpose: Abstract away boilerplate for creating NixOS system configurations
- Examples: `outputs.nix` lines 81-90 (centauri and mirach instantiations)
- Pattern: Takes `{ system, hostname, modules?, extraSpecialArgs? }` and returns a complete `nixpkgs.lib.nixosSystem` with all layers wired
- Benefit: Single point of truth for system layering; adding new machines requires ~8 lines

**Module System:**
- Purpose: NixOS/home-manager's recursive attribute set merging for configuration composition
- Examples: `nixos/machines/centauri/default.nix` lines 4-14 show import list; `nixos/users/djoolz.nix` lines 16-22 show home-manager imports
- Pattern: Each file is a function `{ config, pkgs, lib, ... }: { ... }` returning an attribute set; recursive merge combines all imports
- Benefit: Files can be independently toggled on/off with comments; no explicit ordering needed beyond imports list

**Per-System Package Overlays:**
- Purpose: Allow machines/users to use different nixpkgs versions (stable, unstable, tailscale-pinned)
- Examples: `outputs.nix` lines 25-28, 69-75; used in `nixos/users/djoolz.nix` line 1 as `pkgs-unstable`
- Pattern: Pass as `specialArgs` to `mkNixosSystem`, making `pkgs-unstable` available throughout config
- Benefit: Flexible version pinning without forking entire nixpkgs

**Hardware Configuration Abstraction:**
- Purpose: NixOS's built-in abstraction for hardware discovery
- Examples: `nixos/machines/{hostname}/hardware-configuration.nix`
- Pattern: Generated via `nixos-generate-config` during initial setup; contains CPU, disk, EFI, other hardware settings
- Benefit: Automatic detection; typically not edited manually

## Entry Points

**Flake Entry Point:**
- Location: `flake.nix`
- Triggers: User runs `nix flake`, `nixos-rebuild switch --flake .#hostname`, `nix develop`, `treefmt` (via treefmt.nix)
- Responsibilities:
  - Declares inputs (nixpkgs, home-manager, etc.) and their versions
  - Sets experimental features
  - Delegates system configuration to `outputs.nix`

**System Factory Entry Point:**
- Location: `nixos/configurations.nix`
- Triggers: Called by `outputs.nix` line 47 for each machine
- Responsibilities:
  - Instantiates `mkNixosSystem` for each machine (centauri, mirach)
  - Passes machine hostname and system architecture
  - Wires home-manager integration
  - Configures Nix daemon settings (cache, trusted users, garbage collection)

**Machine-Specific Entry Point:**
- Location: `nixos/machines/{hostname}/default.nix`
- Triggers: Pulled in by `configurations.nix` line 14 (`./machines/${hostname}`)
- Responsibilities:
  - Aggregates machine-specific imports (bootloader, configuration, hardware)
  - Sets hostname parameter
  - Delegates to sub-modules for actual configuration

**User Entry Point:**
- Location: `nixos/users/djoolz.nix`
- Triggers: Imported by home-manager in `configurations.nix` line 23
- Responsibilities:
  - Defines user home directory and username
  - Imports user-level modules (packages, programs, services)
  - Sets home.stateVersion for home-manager compatibility

## Error Handling

**Strategy:** Configuration validation at build time; no runtime error recovery in configs.

**Patterns:**

- **Syntax Errors:** NixOS evaluates configs before building; Nix parser catches syntax errors immediately
- **Missing Modules:** If a machine imports a non-existent module, `nixos-rebuild` fails with "file not found"
- **Circular Dependencies:** Avoided via explicit import list; NixOS module system doesn't allow circular imports
- **Type Mismatches:** Nix's lazy evaluation may defer type errors until evaluation; caught during `nixos-rebuild`
- **Service Failures:** Service startup failures logged to systemd journal; no automatic rollback in configs (handled by `nixos-rebuild switch` vs. `test`)

**Observed Patterns in Codebase:**

- Commented-out imports in `nixos/machines/centauri/configuration.nix` (lines 10-23) show explicit disabling pattern
- Optional hardware sections in `nixos/machines/template/default.nix` (lines 18-31) show capability templating
- TODOs in `outputs.nix` line 52 and `nixos/users/djoolz.nix` line 5 indicate areas with known limitations

## Cross-Cutting Concerns

**Logging:**
- Service logs: systemd journal (accessed via `journalctl`)
- Nix build logs: printed to stdout during `nixos-rebuild`
- No application-level logging abstraction in config

**Validation:**
- Nix type system provides some validation at evaluation time
- Hardware configuration includes filesystem validation
- Service definitions checked against NixOS module options

**Authentication:**
- Home-manager backups stored with `.backup` extension (`nixos/configurations.nix` line 22)
- SSH module available but not enabled by default (`nixos/machines/common/ssh.nix` not imported in centauri)
- GitHub token embedded in `configurations.nix` lines 42-44 for Nix binary cache access (security concern noted)
- Tailscale integration for network authentication (`nixos/machines/common/tailscale.nix`)

**Package Management:**
- Nix handles reproducible package fetching and building
- Multiple nixpkgs versions supported simultaneously (stable, unstable, tailscale-pinned)
- Flatpak integration for containerized application deployment (`nixos/machines/common/services.nix`)
- Automatic garbage collection of old generations (`nixos/machines/common/autoupgrade.nix` lines 27-30)

---

*Architecture analysis: 2026-02-04*
