# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a modular NixOS flake configuration managing multiple machines using flake-parts. The architecture uses:
- **Role-based organization** (workstation, homelab) with machine-specific overrides
- **Self-contained modules** for services, desktop environments, and virtualization
- **Standalone home-manager** configurations decoupled from machines
- **Explicit imports** with no recursive discovery (clear dependencies)

**Current Status:** Refactor to modular structure in progress. See `plan.md` for migration details.

## Getting Started

### Initial Setup (After Cloning)

When you first clone this repository, configure git to use the included pre-commit hooks:

```bash
git config core.hooksPath .githooks
```

This ensures that formatting and validation runs before every commit automatically.

## Essential Commands

### Fast Validation (Preferred During Development)

**IMPORTANT:** Always use `nix eval` for fast validation during development. Building/switching takes too long for iteration.

```bash
# Validate flake structure (catches syntax errors)
nix flake check

# Show all flake outputs
nix flake show

# Evaluate NixOS config (fast, no build)
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel

# Check specific config values
nix eval .#nixosConfigurations.centauri.config.networking.hostName
nix eval .#nixosConfigurations.centauri.config.services.xserver.desktopManager.gnome.enable
nix eval .#nixosConfigurations.centauri.config.virtualisation.docker.rootless.enable

# Evaluate home-manager configs
nix eval .#homeConfigurations."djoolz@workstation".activationPackage
nix eval .#homeConfigurations."djoolz@server".activationPackage

# Test dev shell (quick)
nix develop --command echo "Dev shell works"

# Test formatter
nix fmt -- --version
```

### Building & Deployment (Only When Validation Passes)

```bash
# ONLY use these after all nix eval commands pass

# Dry run to see what would change (faster than full build)
nixos-rebuild dry-build --flake .#centauri

# Test configuration without modifying bootloader
sudo nixos-rebuild test --flake .#centauri

# Apply and add boot entry (when confident)
sudo nixos-rebuild switch --flake .#centauri

# Standalone home-manager (decoupled from NixOS)
home-manager switch --flake .#djoolz@workstation
home-manager switch --flake .#djoolz@server  # CLI-only profile
```

### Code Quality

The repository uses automated pre-commit hooks to ensure code quality. These run automatically before every commit.

**Pre-commit checks:**
1. `nix fmt` - Format all Nix code with treefmt
2. `validate.sh` - Run comprehensive validation tests
3. Commits are blocked if validation fails

**Manual code quality commands:**

```bash
# Format all code (also runs automatically on commit)
nix fmt

# Enter development shell with linting tools
nix develop
# Available tools: nixpkgs-fmt, statix (linter), deadnix (dead code detection)

# Run validation tests anytime
sh validate.sh
```

**Bypassing pre-commit hooks (if necessary):**

```bash
# Use --no-verify flag to skip pre-commit checks
# ⚠️  Only use if you know what you're doing!
git commit --no-verify -m "your message"
```

### Flake Management

```bash
# Update all inputs (updates flake.lock)
nix flake update

# Update specific input
nix flake update nixpkgs

# Show flake structure
nix flake show

# View flake metadata
nix flake metadata
```

### Hardware Configuration

```bash
# Generate hardware configuration for a new machine
sudo nixos-generate-config --show-hardware-config > machines/NEW_MACHINE/hardware-configuration.nix
```

## Architecture

### Core Principles

**Modularity:** Each module is independent and self-contained, focusing on a single feature or concern.

**Self-containment:** A module includes everything needed for its feature - configuration, related packages, user groups, firewall rules, etc. - in one file. This ensures modules can be imported anywhere without hidden dependencies.

**Explicit imports:** No recursive discovery. All imports are explicit and visible, making dependencies clear.

### Configuration Flow

The configuration uses flake-parts with a clear separation of concerns:

1. **Entry**: `flake.nix` declares all inputs (nixpkgs versions, home-manager, etc.)
2. **Orchestration**: `outputs.nix` imports all flake-parts modules (just coordination, no inline config)
3. **perSystem modules**: `parts/` directory contains development tools, formatters, checks
4. **Flake outputs**: `flake/` directory contains machines, homes, exported modules
5. **Reusable modules**: `modules/nixos/` and `modules/home/` contain self-contained feature modules
6. **Machine configs**: `machines/{hostname}/` contain hardware and machine-specific overrides

### Directory Structure

```
mine/
├── flake.nix                          # Input declarations only
├── outputs.nix                        # Minimal orchestrator (imports only)
│
├── parts/                             # perSystem modules (development environment)
│   ├── systems.nix                    # Supported architectures
│   ├── devshells.nix                  # Development shell with linters
│   ├── formatter.nix                  # Treefmt configuration
│   ├── packages.nix                   # Custom packages
│   └── checks.nix                     # CI validation checks
│
├── flake/                             # Flake-level outputs
│   ├── lib.nix                        # Helper functions (mkNixosSystem)
│   ├── machines/                      # Machine definitions by role
│   │   ├── workstations.nix           # Laptop/desktop machines
│   │   └── homelabs.nix               # Server/homelab machines
│   ├── homes/                         # Standalone home-manager configs
│   │   ├── djoolz.nix                 # User configurations
│   │   └── profiles/                  # Reusable home profiles
│   │       ├── common.nix             # CLI-only (for servers)
│   │       ├── desktop.nix            # GUI + development tools
│   │       └── development.nix        # Additional dev tools
│   └── modules.nix                    # Exported nixosModules/homeModules
│
├── modules/                           # Reusable NixOS & Home modules
│   ├── nixos/
│   │   ├── desktop/                   # Desktop environments (GNOME, Plasma)
│   │   │   ├── common.nix             # Shared desktop infrastructure (audio/printing/bluetooth/etc.)
│   │   ├── virtualisation/            # Docker, Podman, libvirtd, QuickEMU
│   │   ├── services/                  # Tailscale, SSH, Android, etc.
│   │   ├── system/                    # Locale, shell, power, nix-settings
│   │   └── roles/                     # Role profiles (workstation, homelab)
│   └── home/                          # Home-manager modules
│       ├── programs/                  # Program configurations
│       ├── packages/                  # Package lists
│       ├── dconf/                     # GNOME/dconf settings
│       └── plasma/                    # KDE Plasma home-manager settings (plasma-manager)
│
└── machines/                          # Machine-specific configurations
    ├── centauri/                      # Primary laptop/workstation
    │   ├── default.nix                # Machine config + role imports
    │   ├── hardware-configuration.nix # Hardware scan output
    │   ├── bootloader.nix             # Boot configuration
    │   └── other-hardware.nix         # Additional hardware settings
    ├── mirach/                        # Homelab server
    │   ├── default.nix
    │   ├── hardware-configuration.nix
    │   └── services/                  # Machine-specific services
    │       └── homeassistant.nix
    └── template/                      # Template for new machines
```

### Multiple nixpkgs Versions

Three nixpkgs versions are available throughout all configs:

- **`pkgs`**: Stable channel (nixos-25.11) - default for most packages
- **`pkgs-unstable`**: Rolling channel (nixos-unstable) - for packages needing newer versions
- **`pkgs-tailscale`**: Pinned commit for Tailscale stability

Access in any config: `pkgs-unstable.package-name` or `pkgs-tailscale.package-name`

### Roles

Machines are organized by role with machine-specific overrides:

- **Workstation**: Interactive desktop for development (Centauri)
   - Includes: Desktop environment (via desktop module), power management, networking
   - Virtualization: Docker rootless for development containers

- **Homelab**: Server with optional GUI for management (Mirach)
  - Includes: SSH server, Tailscale, firewall
  - Virtualization: libvirtd for VMs, Docker for services
  - Optional: GNOME for management interface

## Common Tasks

### Adding a New Machine

1. **Create machine directory:**
   ```bash
   mkdir -p machines/NEW_MACHINE
   ```

2. **Generate hardware config:**
   ```bash
   sudo nixos-generate-config --show-hardware-config > machines/NEW_MACHINE/hardware-configuration.nix
   ```

3. **Create `machines/NEW_MACHINE/default.nix`:**
   ```nix
   { config, pkgs, hostname, ... }:
   {
     # NEW_MACHINE - [Description]
     # Hardware: [Hardware details]
     # Role: [workstation|homelab]

     imports = [
       ./hardware-configuration.nix
       # Add other machine-specific configs
     ];

     networking.hostName = hostname;

     # User configuration
     users.users.djoolz = {
       isNormalUser = true;
       description = "djoolz";
       extraGroups = [ "networkmanager" "wheel" ];
     };

     # Home-manager profile
     home-manager.users.djoolz = import ../../flake/homes/profiles/desktop.nix;

     system.stateVersion = "25.11";
   }
   ```

4. **Add to appropriate machine list:**
   - For workstation: `flake/machines/workstations.nix`
   - For homelab: `flake/machines/homelabs.nix`

   ```nix
   NEW_MACHINE = self.lib.mkNixosSystem {
     system = "x86_64-linux";
     hostname = "NEW_MACHINE";
     role = "workstation";  # or "homelab"
     desktop = "gnome";     # or "plasma", "niri", etc. (optional)
     modules = [
       # Virtualization (choose as needed)
       # ../../modules/nixos/virtualisation/docker-rootless.nix
       # ../../modules/nixos/virtualisation/libvirtd.nix
     ];
   };
   ```

5. **Validate:**
   ```bash
   nix eval .#nixosConfigurations.NEW_MACHINE.config.system.build.toplevel
   nix eval .#nixosConfigurations.NEW_MACHINE.config.networking.hostName
   ```

6. **Build when ready:**
   ```bash
   sudo nixos-rebuild test --flake .#NEW_MACHINE
   ```

### Switching Desktop Environments

Desktop environments are managed via the `desktop` parameter in `mkNixosSystem`. Desktop modules are self-contained and import `modules/nixos/desktop/common.nix` for shared infrastructure.

**Available desktop environments:**
- `gnome` - GNOME desktop with GDM display manager
- `plasma` - KDE Plasma 6 with SDDM display manager
- Others can be added as modules in `modules/nixos/desktop/`

**To switch desktop on an existing machine:**

1. Edit `flake/machines/workstations.nix` or `flake/machines/homelabs.nix`
2. Change the `desktop` parameter:
   ```nix
   centauri = self.lib.mkNixosSystem {
     system = "x86_64-linux";
     hostname = "centauri";
     role = "workstation";
     desktop = "plasma";  # Changed from "gnome"
     modules = [ ... ];
   };
   ```

3. Validate the change:
   ```bash
   nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
   ```

4. If validation passes, test and switch:
   ```bash
   sudo nixos-rebuild test --flake .#centauri
   sudo nixos-rebuild switch --flake .#centauri  # When confident
   ```

**To create a new desktop environment module:**

1. Create `modules/nixos/desktop/my-de.nix`:
   ```nix
   { config, lib, pkgs, ... }: {
       imports = [ ./common.nix ];
     services.desktopManager.myDE.enable = true;
     # Add other DE-specific configuration
   }
   ```

2. Then use it in any machine definition:
   ```nix
   desktop = "my-de";
   ```

**Note:** The `desktop` parameter is optional. Machines without a desktop environment can omit it for headless/server configurations.

### Adding a New Module

#### NixOS Module (Service, Desktop Environment, etc.)

1. **Create in appropriate category:**
   ```bash
   # For a service:
   nano modules/nixos/services/my-service.nix

   # For desktop environment:
   nano modules/nixos/desktop/my-desktop.nix
   ```

2. **Make it self-contained:**

   A self-contained module includes **everything** needed for that feature to work:
   - Service/application configuration
   - Related packages needed for the service
   - User groups and permissions
   - Firewall rules (if networking)
   - Environment variables
   - File permissions
   - Kernel parameters (if needed)

   ```nix
   { config, lib, pkgs, ... }:
   {
     # My Service
     # Description of what this module provides
     # Related configuration: firewall rules, user groups, environment setup
     # Dependencies: [list any external dependencies]

     services.my-service = {
       enable = true;
       # ... configuration ...
     };

     # Include ALL related config here - firewall, users, packages, etc.
     networking.firewall.allowedTCPPorts = [ 1234 ];
     users.users.djoolz.extraGroups = [ "my-service-group" ];

     # Related packages
     environment.systemPackages = with pkgs; [
       my-service-cli-tool
       # ... other related tools ...
     ];
   }
   ```

3. **Module isolation - what NOT to do:**
   ```nix
   # ❌ WRONG: Service config here
   services.my-service.enable = true;

   # ❌ WRONG: User group config in another file
   # In some other file: users.users.djoolz.extraGroups = [ "my-service" ];

   # ✅ RIGHT: Everything together in one module
   { config, lib, pkgs, ... }:
   {
     services.my-service.enable = true;
     users.users.djoolz.extraGroups = [ "my-service" ];
     # ... all related config ...
   }
   ```

4. **Import in machine or role:**
   - In `flake/machines/*.nix` for machine-specific modules
   - In `modules/nixos/roles/*.nix` for all machines with that role
   - In `flake/homes/profiles/*.nix` for home-manager modules

5. **Export if reusable (optional):**
   Add to `flake/modules.nix`:
   ```nix
   flake.nixosModules = {
     my-service = ./modules/nixos/services/my-service.nix;
   };
   ```

6. **Test module independence:**
   ```bash
   # Verify module can be imported standalone
   nix eval .#nixosConfigurations.centauri.config.services.my-service.enable
   ```

#### Home-Manager Module

1. **Create in home modules:**
   ```bash
   nano modules/home/programs/my-program.nix
   ```

2. **Import in home profile:**
   - `flake/homes/profiles/common.nix` for all profiles
   - `flake/homes/profiles/desktop.nix` for GUI-only

### Module Boundaries & When to Split/Combine

**Single concern principle:**
- Each module should do one thing well
- A module file should be focused and understandable at a glance
- If a module becomes too large (>100 lines), consider splitting by concern

**When to keep together (single module):**
- A service + its firewall rules
- A service + required user groups
- Related configuration for one feature

**When to split (separate modules):**
- Different services that don't depend on each other (e.g., `docker.nix`, `tailscale.nix`)
- Different desktop environments (e.g., `gnome.nix`, `plasma.nix`)
- System-level config categories (e.g., `locale.nix`, `shell.nix`)

**Example: Good module boundaries**
```
modules/nixos/services/
├── tailscale.nix         # Single concern: VPN service + firewall
├── firewall.nix          # Single concern: General firewall rules
└── flatpak.nix           # Single concern: Flatpak runtime

modules/nixos/system/
├── locale.nix            # Single concern: Timezone, locale
├── shell.nix             # Single concern: Shell configuration
└── nix-settings.nix      # Single concern: Nix daemon settings
```

### Modifying an Existing Module

1. **Locate the module** using the directory structure
2. **Edit the module** directly
3. **Validate quickly:**
   ```bash
   nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
   ```
4. **Test on a machine:**
   ```bash
   sudo nixos-rebuild test --flake .#centauri
   ```

## Best Practices (DOs)

### Configuration

- ✅ **DO** use `nix eval` for fast iteration during development
- ✅ **DO** validate with `nix flake check` before committing
- ✅ **DO** make modules self-contained (all related config in one file)
- ✅ **DO** add descriptive comments to each module explaining its purpose
- ✅ **DO** use role profiles for shared configuration across machines
- ✅ **DO** keep machine-specific config in `machines/{hostname}/`
- ✅ **DO** use `pkgs-unstable` for packages requiring newer versions
- ✅ **DO** export reusable modules in `flake/modules.nix`
- ✅ **DO** use standalone home-manager for user configurations
- ✅ **DO** test changes with `nixos-rebuild test` before switching
- ✅ **DO** commit after each successful validation
- ✅ **DO** use `lib.mkDefault` for role defaults that machines can override

### Module Organization

- ✅ **DO** put desktop environments in `modules/nixos/desktop/`
- ✅ **DO** put virtualization in `modules/nixos/virtualisation/`
- ✅ **DO** put services in `modules/nixos/services/`
- ✅ **DO** put system config in `modules/nixos/system/`
- ✅ **DO** use roles for common machine profiles
- ✅ **DO** make imports explicit (no recursive discovery)

### Security

- ✅ **DO** use agenix or sops-nix for secrets
- ✅ **DO** reference secrets via file paths, never inline
- ✅ **DO** keep CPU mitigations enabled (`mitigations=auto`)
- ✅ **DO** disable password authentication for SSH
- ✅ **DO** use firewall on homelab machines

## Best Practices (DON'Ts)

### Configuration

- ❌ **DON'T** use `nixos-rebuild switch` for validation (too slow)
- ❌ **DON'T** use `nix build` during development (use `nix eval`)
- ❌ **DON'T** put shared config in machine-specific directories
- ❌ **DON'T** duplicate configuration across multiple modules
- ❌ **DON'T** use recursive imports (makes dependencies unclear)
- ❌ **DON'T** import machine configs from other machines
- ❌ **DON'T** hardcode values that should be in `specialArgs`
- ❌ **DON'T** mix NixOS system config with home-manager config in the same file
- ❌ **DON'T** create circular dependencies between modules
- ❌ **DON'T** use `lib.mkForce` unless absolutely necessary (indicates design issue)

### Module Organization

- ❌ **DON'T** put modules in `machines/common/` (use `modules/nixos/` instead)
- ❌ **DON'T** create deeply nested module hierarchies (keep flat)
- ❌ **DON'T** put machine-specific config in shared modules
- ❌ **DON'T** create "god modules" that do everything (keep focused)
- ❌ **DON'T** mix concerns (e.g., networking + virtualization in one module)
- ❌ **DON'T** split related config across multiple files (keep service + dependencies together)
- ❌ **DON'T** assume hidden dependencies (always include everything a module needs in that file)
- ❌ **DON'T** require users to import multiple files for one feature (module should be standalone)

### Security

- ❌ **DON'T** commit secrets to git (use secrets management)
- ❌ **DON'T** disable security features without documentation
- ❌ **DON'T** use `mitigations=off` on networked machines
- ❌ **DON'T** enable password authentication for SSH
- ❌ **DON'T** disable the firewall without explicit reason

### Home-Manager

- ❌ **DON'T** couple home-manager configs to specific machines
- ❌ **DON'T** use different home-manager versions than nixpkgs
- ❌ **DON'T** duplicate package lists across profiles (use imports)
- ❌ **DON'T** regenerate dconf.nix without backing up manual changes

## Critical Security Issues

### Secrets Management

**NEVER commit secrets to git.** Use proper secrets management:

- Use `agenix` (already in inputs) or `sops-nix` for encrypted secrets
- Reference secrets via file paths: `/run/secrets/my-secret`
- Add secret files to `.gitignore`
- Rotate any secrets that were accidentally committed

Example using agenix:
```nix
# In machine config
age.secrets.my-secret.file = ../../secrets/my-secret.age;

# In service
services.myservice.passwordFile = config.age.secrets.my-secret.path;
```

### CPU Mitigations

`machines/centauri/bootloader.nix` may disable Spectre/Meltdown mitigations with `mitigations=off`.

- Only acceptable for air-gapped machines
- For networked machines: Remove or use `mitigations=auto`
- Documents why if disabled for performance reasons

## Known Issues & Workarounds

### Powertop Service Crashes on Boot

- **Location:** `modules/nixos/system/powermanagement.nix`
- **Issue:** Service coredumps every boot, configured to restart automatically
- **Debug:** `journalctl -u powertop -n 50`
- **Workaround:** Currently tolerates crash and restarts; consider switching to `tlp` if problematic

### Auto-Upgrade Disabled

- **Location:** `modules/nixos/system/autoupgrade.nix` (commented out)
- **Reason:** Root permission issues prevent automatic upgrades
- **Impact:** Requires manual upgrades: `nix flake update && sudo nixos-rebuild switch --flake .#hostname`

### Dconf Settings (GNOME)

- **Location:** `modules/home/dconf/dconf.nix`
- **Auto-generated:** Created by `dconf2nix`
- **Fragile:** Large auto-generated file; manual edits lost on regeneration
- **Best practice:**
  - Export only changed sections: `dconf dump /org/gnome/desktop/interface/ | dconf2nix`
  - Merge manually into existing file
  - Never regenerate entire file without backing up manual changes first

## Testing Strategy

### Fast Iteration Loop (Primary)

```bash
# 1. Make changes to modules
# 2. Fast validation (under 1 second each)
nix flake check
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel

# 3. Check specific settings propagated
nix eval .#nixosConfigurations.centauri.config.services.xserver.enable
nix eval .#nixosConfigurations.centauri.config.networking.hostName

# 4. If all evals pass, move to slower validation
```

### Build Testing (When Evals Pass)

```bash
# 1. Dry run (faster, shows what would change)
nixos-rebuild dry-build --flake .#centauri

# 2. Test without bootloader modification
sudo nixos-rebuild test --flake .#centauri

# 3. When confident, switch permanently
sudo nixos-rebuild switch --flake .#centauri
```

### Validation Script

Use `validate.sh` for comprehensive testing:
```bash
./validate.sh  # Validates all configurations quickly
```

## Git Workflow

### Pre-commit

- **Auto-formatting:** treefmt runs automatically on commit
- **Flake.lock:** Automatically staged when updated
- **Pre-push hooks:** Prevent unformatted code from being pushed

### Commit Strategy

1. Make changes to modules
2. Run `nix eval` commands for fast validation
3. Run `nix flake check`
4. Commit with descriptive message
5. Test build only when ready to deploy

### Conventional Commits

Use semantic commit messages:
- `feat:` New feature or module
- `fix:` Bug fix
- `refactor:` Code restructuring without behavior change
- `docs:` Documentation updates
- `chore:` Maintenance tasks

Example: `feat(modules): add KDE Plasma desktop environment`

## Common Troubleshooting

### "file not found" on evaluation

- Check all `imports = [ ... ]` paths are correct relative to the importing file
- Verify file exists: `ls -la modules/nixos/services/MISSING_FILE.nix`
- Check for typos in paths (common with deep directories)

### Module evaluation errors

```bash
# Check flake structure is valid
nix flake show

# Parse individual files for syntax errors
nix-instantiate --parse modules/nixos/desktop/gnome.nix

# Detailed evaluation trace
nix eval --show-trace .#nixosConfigurations.centauri.config.system.build.toplevel
```

### Conflicting module options

- Check for duplicate imports of the same module
- Look for `lib.mkForce` overriding role defaults inappropriately
- Verify only one desktop environment is enabled
- Check only one virtualization backend is active (Docker OR Podman, not both)

### Missing packages after changes

```bash
# Search for package in stable channel
nix search nixpkgs PACKAGE_NAME

# Search in unstable
nix search nixpkgs#nixpkgs-unstable PACKAGE_NAME

# Check if package was renamed
# Look at nixpkgs release notes for your version
```

### Home-manager activation failures

```bash
# Evaluate home config for errors
nix eval .#homeConfigurations."djoolz@workstation".activationPackage

# Check home-manager logs
journalctl --user -u home-manager-djoolz

# Dry-run activation
home-manager switch --flake .#djoolz@workstation --dry-run
```

### Slow evaluation times

- Avoid using `--show-trace` unless debugging (adds significant overhead)
- Use `nix eval` instead of `nix build` during development
- Check for infinite recursion in module imports
- Verify no circular dependencies between modules

## Performance Notes

- **Parallel builds:** Nix automatically uses all CPU cores
- **Binary cache:** Configured for `nix-community.cachix.org` and `hetzner-cache.numtide.com`
- **Store optimization:** Auto-optimization enabled in `modules/nixos/system/nix-settings.nix`
- **Garbage collection:** Manual garbage collection with `nix-collect-garbage -d`
- **Fast validation:** Always use `nix eval` for iteration, only build when deploying

## Advanced Topics

### Using This Config in Other Flakes

This configuration exports reusable modules:

```nix
{
  inputs.my-config.url = "github:djoolz/nixos-config";

  # Use exported modules
  imports = [
    inputs.my-config.nixosModules.gnome
    inputs.my-config.nixosModules.tailscale
  ];

  # Use home modules
  home-manager.users.myuser = {
    imports = [ inputs.my-config.homeModules.desktop ];
  };
}
```

### Remote Deployment

For deploying to remote machines, consider:
- `deploy-rs` for push-based deployment
- `colmena` for managing multiple machines
- `nixos-anywhere` for provisioning new machines

### CI/CD Integration

Automate validation in CI:
```yaml
# .github/workflows/check.yml
- run: nix flake check
- run: nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
- run: nix eval .#nixosConfigurations.mirach.config.system.build.toplevel
```

## Migration Notes

**Current Status:** This repository is undergoing refactoring to the modular structure described above.

- See `plan.md` for detailed migration plan and phases
- Old structure: `nixos/machines/common/` → New: `modules/nixos/`
- Old: Coupled home-manager → New: Standalone `homeConfigurations`
- Old: Flat machine list → New: Role-based organization

During migration, both old and new structures may coexist. Always validate with `nix eval` after changes.
