# Coding Conventions

**Analysis Date:** 2026-02-04

## Naming Patterns

**Files:**
- Module files: snake_case (e.g., `bootloader.nix`, `shell.nix`, `hardware-configuration.nix`)
- Default entry points: `default.nix` (e.g., `nixos/machines/centauri/default.nix`)
- Configuration files: descriptive snake_case (e.g., `djoolz.nix` for user configs, `gnome.nix` for service configs)
- Scripts: snake_case with `.sh` extension (e.g., `test-bridge-networking.sh`)

**Functions:**
- Camel case (e.g., `mkNixosSystem` in `nixos/configurations.nix`)
- Prefixed with action verb (mk = make, with = with configuration)
- Example pattern: `mkNixosSystem = { system, hostname, modules ? [ ], extraSpecialArgs ? { } }: ...`

**Variables:**
- camelCase for arguments and let-bindings (e.g., `extraSpecialArgs`, `pkgs-unstable`, `pkgs-tailscale`)
- snake_case for option paths (e.g., `boot.loader.systemd-boot.enable`, `services.flatpak`, `users.users.djoolz`)
- Hyphens in attribute names for NixOS options (e.g., `boot.loader.efi.canTouchEfiVariables`, `services.displayManager.gdm`)
- Prefix pkgs variants to distinguish them: `pkgs`, `pkgs-unstable`, `pkgs-tailscale` (see `nixos/configurations.nix` line 69-76)

**Types:**
- Options use full path (e.g., `boot.supportedFilesystems`, `services.tailscale`, `environment.systemPackages`)
- List attributes with `with pkgs;` to access package names (e.g., lines 97-110 in `nixos/machines/centauri/configuration.nix`)
- Boolean flags use `enable` suffix (e.g., `services.tailscale.enable`, `boot.loader.systemd-boot.enable`)

## Code Style

**Formatting:**
- Tool: `treefmt-nix` with `nixfmt-classic` (configured in `treefmt.nix`)
- YAML: formatted with `yamlfmt` (enabled in treefmt.nix)
- Python: formatted with `black` (enabled in treefmt.nix)
- Run formatting: `nix flake check` or `treefmt` command triggers nixfmt-classic
- Indentation: 2 spaces (standard Nix convention)

**Linting:**
- Tool: `statix` (included in devShell in `outputs.nix` line 34)
- Additional tools: `deadnix` (check for dead code), `nixpkgs-fmt` (alternative formatter)
- Configured in `.planning/` with linting via flake development environment
- Exclude patterns in treefmt.nix (line 19-30): facts directories, gpg/pub keys, git-crypt, images, license files

## Import Organization

**Order:**
1. Module function parameter destructuring at top: `{ config, pkgs, lib, hostname, ... }:`
2. Relative imports with `./` (e.g., `./bootloader.nix`, `./hardware-configuration.nix`)
3. Absolute imports without `./` (e.g., `../common/gnome.nix`, `../users/djoolz.nix`)
4. Parent directory traversal: `../` for accessing shared modules (see `nixos/machines/centauri/default.nix` lines 4-13)

**Path Aliases:**
- Not explicitly used; direct relative imports with `./` and `../` patterns
- specialArgs in `nixos/configurations.nix` provide access to unpacked inputs:
  - `inputs` (line 67): flake inputs passed through
  - `hostname` (line 68): machine hostname
  - `pkgs-unstable` (line 69-72): unstable channel packages
  - `pkgs-tailscale` (line 73-76): specific tailscale nixpkgs version

## Error Handling

**Patterns:**
- No explicit error handling visible; NixOS declarative model handles errors at build time
- Null safety through defaults: `modules ? [ ]` (optional with default empty list in line 6 of `nixos/configurations.nix`)
- Option inheritance via `config` parameter lets modules check other configs before setting values
- Firewall configuration uses explicit enablement pattern (e.g., `networking.firewall.allowedUDPPorts` in `nixos/machines/common/tailscale.nix` line 11)

**Validation Approach:**
- NixOS type system validates options at build time
- Hardware-specific configs validated by hardware-configuration.nix (auto-generated)
- Service enablement gates dependent configuration (e.g., only configure Flatpak when `services.flatpak.enable = true`)

## Logging

**Framework:** Not applicable - this is declarative NixOS configuration

**Patterns:**
- Comments used instead of runtime logging
- Build output visible during `nixos-rebuild` commands
- Shell script for testing: `test-bridge-networking.sh` uses `echo` statements with visual indicators (`✓` and `✗`) for diagnostics
- Example from `test-bridge-networking.sh` (lines 6-10): structured output with section headers

## Comments

**When to Comment:**
- Explain non-obvious NixOS options (e.g., `"nohz_full=2-7" # NixOS produces many wakeups per second...` in bootloader.nix line 18)
- Document why a configuration choice was made (e.g., comments in `nixos/machines/centauri/configuration.nix` explaining module inclusion)
- Link to external documentation (e.g., `# https://nixos.wiki/wiki/KDE` in gnome.nix line 3)
- Warn about dangerous settings (e.g., `FIXME dangerous.` in bootloader.nix line 19)
- Explain hardware-specific choices (e.g., comments about GPU tools in centauri configuration)

**Comment Pattern:**
- Inline comments with `#` at end of line: `boot.kernelModules = [ "kvm-intel" # for Intel virtualization support ];`
- Block comments: lines starting with `# ` (see configuration files)
- Section separators: comment lines with repeating `#` symbols (e.g., `## Fonts & LibreOffice ##########` in packages.nix line 7)
- Disabled code in comments for reference (e.g., commented imports in centauri/default.nix lines 9-11)

**Documentation Comments:**
- Links to wiki pages or source documentation (e.g., `# https://nix.dev/permalink/stub-ld` in configuration.nix line 53)
- NixOS manual references (e.g., `configuration.nix(5)` mentioned in file headers)
- GitHub repository links (e.g., `# https://github.com/nix-community/dconf2nix` in gnome.nix line 35)

## Function Design

**Size:**
- Small, focused functions - example: `mkNixosSystem` in `nixos/configurations.nix` (lines 6-78) creates complete system definition
- Typically single responsibility: bootloader config, shell setup, service config, user packages

**Parameters:**
- Destructured at function signature: `{ config, pkgs, lib, hostname, ... }`
- Required vs optional indicated with `?` for defaults: `modules ? [ ]` (nixos/configurations.nix line 6)
- Special args passed via `specialArgs` in flake output (lines 66-77 in configurations.nix)

**Return Values:**
- Single attribute set returned (implicit return of final let-binding)
- Nested attribute sets for configuration (e.g., `services = { ... }` pattern)
- Lists for repeatable items (e.g., `environment.systemPackages = with pkgs; [ item1 item2 ... ];`)

## Module Design

**Exports:**
- Single attribute set from each module file
- Named options (e.g., `boot.loader`, `services.flatpak`, `users.users.djoolz`)
- No explicit exports; everything is module configuration

**Barrel Files:**
- `default.nix` files act as entry points (e.g., `nixos/machines/centauri/default.nix`)
- Used to declare imports and compose multiple configuration files
- Pattern: imports list (lines 4-13) declares sub-modules, then config (lines 16-29) provides machine-specific settings

**Module Composition:**
- Via `imports = [ ]` list at top of each module
- Relative paths with `./` for siblings, `../` for parent modules
- `home-manager.nixosModules.home-manager` imported to enable home-manager integration (configurations.nix line 17)
- Flake modules imported via `inputs.X.flakeModules.Y` pattern (outputs.nix lines 16-17)

---

*Convention analysis: 2026-02-04*
