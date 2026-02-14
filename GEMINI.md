# NixOS Configuration Project - Gemini CLI Context

This document provides a comprehensive overview of the NixOS configuration project, intended to serve as instructional context for future interactions with the Gemini CLI. It draws heavily from the project's internal documentation (`CLAUDE.md`) to ensure accuracy and completeness.

## Repository Overview

This is a modular NixOS flake configuration managing multiple machines using flake-parts. The architecture is designed for clarity and reusability, featuring:
- **Role-based organization** (workstation, homelab) with machine-specific overrides.
- **Self-contained modules** for services, desktop environments, and virtualization.
- **Standalone home-manager** configurations decoupled from specific machines.
- **Explicit imports** with no recursive discovery, ensuring clear dependencies.

**Current Status:** Modular structure migration substantially complete (~90%). See `plan.md` for details.

## Getting Started

### Initial Setup (After Cloning)

To ensure automatic code quality checks and consistent development, configure git to use the included pre-commit hooks:

```bash
git config core.hooksPath .githooks
```

## Essential Commands

This section outlines key commands for development, building, and deployment.

### Fast Validation (Preferred During Development)

**IMPORTANT:** Always use `nix eval` for rapid validation during development. Building or switching configurations can be time-consuming and is not suitable for iterative checks.

```bash
# Validate flake structure (catches syntax errors)
nix flake check

# Show all flake outputs
nix flake show

# Evaluate NixOS config (fast, no build) for specific machines
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
# nix eval .#nixosConfigurations.mirach.config.system.build.toplevel

# Check specific configuration values (replace with actual path)
nix eval .#nixosConfigurations.centauri.config.networking.hostName
nix eval .#nixosConfigurations.centauri.config.services.xserver.desktopManager.gnome.enable
nix eval .#nixosConfigurations.centauri.config.virtualisation.docker.rootless.enable

# Evaluate home-manager configurations
nix eval .#homeConfigurations."djoolz@workstation".activationPackage
nix eval .#homeConfigurations."djoolz@server".activationPackage

# Test the development shell quickly
nix develop --command echo "Dev shell works"

# Test the formatter
nix fmt -- --version
```

### Building & Deployment (Only When Validation Passes)

Only proceed with these commands after all `nix eval` and `nix flake check` commands pass successfully.

```bash
# Dry run to see what changes would be applied (faster than full build)
sudo nixos-rebuild dry-build --flake .#centauri

# Test configuration without modifying the bootloader (safe for testing)
sudo nixos-rebuild test --flake .#centauri

# Apply and add boot entry (use when confident in changes)
sudo nixos-rebuild switch --flake .#centauri

# Apply standalone home-manager configuration (decoupled from NixOS switch)
home-manager switch --flake .#djoolz@workstation
# home-manager switch --flake .#djoolz@server  # CLI-only profile
```

### Code Quality

The repository enforces code quality through automated pre-commit hooks, which run automatically before every commit.

**Pre-commit checks include:**
1.  `nix fmt` - Automatic formatting of all Nix code using `treefmt`.
2.  `validate.sh` - Execution of comprehensive validation tests.
Commits will be blocked if any of these validation steps fail.

**Manual code quality commands:**

```bash
# Format all code (also runs automatically on commit)
nix fmt

# Enter development shell with linting and analysis tools
nix develop
# Available tools: nixpkgs-fmt (formatter), statix (linter), deadnix (dead code detection)

# Run validation tests at any time
sh validate.sh
```

**Bypassing pre-commit hooks (use with caution):**

```bash
# Use --no-verify flag to skip pre-commit checks
# ⚠️  Only use if you are fully aware of the implications!
git commit --no-verify -m "your message"
```

### Flake Management

```bash
# Update all flake inputs (updates flake.lock)
nix flake update

# Update a specific input (e.g., nixpkgs)
nix flake update nixpkgs

# Show the flake structure and its outputs
nix flake show

# View detailed flake metadata
nix flake metadata
```

### Hardware Configuration

```bash
# Generate hardware configuration for a new machine (run on the target machine)
sudo nixos-generate-config --show-hardware-config > machines/NEW_MACHINE/hardware-configuration.nix
```

## Architecture

### Core Principles

**Modularity:** Each module is designed to be independent and self-contained, focusing on a single feature or concern.

**Self-containment:** A module includes everything necessary for its feature to function, such as configuration, related packages, user groups, firewall rules, etc., all within a single file. This ensures modules can be imported without hidden dependencies.

**Explicit imports:** All module imports are explicit and clearly visible, making the dependency graph transparent and preventing unexpected behavior from recursive discovery.

### Configuration Flow

The configuration utilizes `flake-parts` to establish a clear separation of concerns:

1.  **Entry:** `flake.nix` declares all external inputs (e.g., `nixpkgs` versions, `home-manager`).
2.  **Orchestration:** `outputs.nix` imports `flake-parts` modules and coordinates the flake's outputs, without containing inline configuration itself.
3.  **`perSystem` modules:** The `parts/` directory contains modules defining development environments, formatters, and CI checks that apply per system.
4.  **Flake outputs:** The `flake/` directory defines the core outputs like machine configurations (`nixosConfigurations`), home-manager configurations (`homeConfigurations`), and exported modules.
5.  **Reusable modules:** The `modules/nixos/` and `modules/home/` directories house self-contained feature modules for NixOS and Home-Manager respectively.
6.  **Machine configurations:** The `nixos/machines/{hostname}/` directories contain hardware-specific settings and machine-specific overrides.

### Directory Structure

```
mine/
├── flake.nix                          # Input declarations only
├── outputs.nix                        # Minimal orchestrator (imports only)
│
├── parts/                             # perSystem modules (development environment)
│   ├── systems.nix                    # Supported architectures (x86_64-linux, aarch64-linux)
│   ├── devshells.nix                  # Development shell with linters (statix, deadnix)
│   ├── formatter.nix                  # Treefmt configuration for Nix code
│   ├── packages.nix                   # Custom packages defined in the flake
│   └── checks.nix                     # CI validation checks
│
├── flake/                             # Flake-level outputs
│   ├── lib.nix                        # Helper functions (e.g., mkNixosSystem)
│   ├── machines/                      # Machine definitions by role
│   │   ├── workstations.nix           # Laptop/desktop machine definitions (e.g., centauri)
│   │   └── homelabs.nix               # Server/homelab machine definitions
│   └── homes/                         # Standalone home-manager configurations
│       ├── djoolz.nix                 # User-specific home-manager configurations
│       └── profiles/                  # Reusable home-manager profiles
│           ├── common.nix             # CLI-only profile (for servers)
│           └── desktop.nix            # GUI + development tools profile
│
├── modules/                           # Reusable NixOS & Home-Manager modules
│   ├── nixos/
│   │   ├── desktop/                   # Desktop environments (GNOME, Plasma, etc.)
│   │   │   ├── common.nix             # Shared desktop infrastructure (audio/printing/bluetooth/etc.)
│   │   │   ├── gnome.nix              # GNOME desktop with GDM
│   │   │   ├── plasma.nix             # KDE Plasma 6 with SDDM
│   │   │   └── gsconnect.nix          # GSConnect/KDE Connect integration
│   │   ├── virtualisation/            # Virtualization technologies (Docker, Podman, libvirtd)
│   │   ├── services/                  # System services (Tailscale, SSH, etc.)
│   │   ├── system/                    # Core system configurations (Locale, shell, power, Nix settings)
│   │   └── roles/                     # Role profiles (workstation, homelab)
│   └── home/                          # Home-Manager specific modules
│       ├── programs/                  # Program configurations
│       ├── packages/                  # User-specific package lists
│       ├── dconf/                     # GNOME/dconf settings
│       └── plasma/                    # KDE Plasma home-manager settings (plasma-manager)
│
└── nixos/                             # Machine-specific configurations
    └── machines/
        ├── centauri/                  # Primary laptop/workstation
        │   ├── default.nix            # Machine config + role imports
        │   ├── hardware-configuration.nix # Hardware scan output
        │   ├── bootloader.nix         # Boot configuration
        │   └── other-hardware.nix     # Additional hardware settings
        └── mirach/                    # Homelab server
            ├── default.nix
            └── hardware-configuration.nix

```

### Multiple nixpkgs Versions

The configuration provides access to three distinct `nixpkgs` versions:

-   **`pkgs`**: The stable channel (`nixos-25.11`), used as the default for most packages.
-   **`pkgs-unstable`**: The rolling `nixos-unstable` channel, for packages requiring newer versions or features.
-   **`pkgs-tailscale`**: A specific pinned commit of `nixpkgs` to ensure stability for Tailscale.

These can be accessed within configurations using `pkgs-unstable.package-name` or `pkgs-tailscale.package-name`.

### Roles

Machines are categorized by roles, with machine-specific overrides for flexibility:

-   **Workstation**: Configured for interactive desktop use and development (e.g., `centauri`). Includes desktop environment (via desktop module), power management, networking, and often virtualization like Docker rootless for development containers.
-   **Homelab**: Designed for server functionalities, potentially with an optional GUI for management (e.g., `mirach`). Includes SSH server, Tailscale, firewall, and virtualization technologies like `libvirtd` and Docker for services.

## Common Tasks

### Adding a New Machine

1.  **Create machine directory:**
    ```bash
    mkdir -p nixos/machines/NEW_MACHINE
    ```

2.  **Generate hardware configuration** (run on the target machine):
    ```bash
    sudo nixos-generate-config --show-hardware-config > nixos/machines/NEW_MACHINE/hardware-configuration.nix
    ```

3.  **Create `nixos/machines/NEW_MACHINE/default.nix`:**
    ```nix
    { config, pkgs, hostname, ... }:
    {
      # NEW_MACHINE - [Description of the new machine]
      # Hardware: [Hardware details, e.g., AMD Ryzen 7]
      # Role: [workstation|homelab]

      imports = [
        ./hardware-configuration.nix
        # Add other machine-specific configurations here if needed
      ];

      networking.hostName = hostname;

      # Example user configuration
      users.users.djoolz = {
        isNormalUser = true;
        description = "djoolz";
        extraGroups = [ "networkmanager" "wheel" ];
      };

      # Example home-manager profile for the user on this machine
      home-manager.users.djoolz = import ../../flake/homes/profiles/desktop.nix;

      system.stateVersion = "25.11"; # Ensure this matches your nixpkgs version
    }
    ```

4.  **Add to appropriate machine list** in `flake/machines/workstations.nix` or `flake/machines/homelabs.nix`:
    ```nix
    NEW_MACHINE = self.lib.mkNixosSystem {
      system = "x86_64-linux"; # or "aarch64-linux"
      hostname = "NEW_MACHINE";
      role = "workstation";  # or "homelab"
      desktop = "gnome";     # Optional: "gnome", "plasma", or other defined desktop modules
      modules = [
        # Add virtualization modules or other machine-specific modules as needed
        # ../../modules/nixos/virtualisation/docker_rootless.nix  # underscore, not hyphen
      ];
    };
    ```

5.  **Validate the new configuration:**
    ```bash
    nix eval .#nixosConfigurations.NEW_MACHINE.config.system.build.toplevel
    nix eval .#nixosConfigurations.NEW_MACHINE.config.networking.hostName
    ```

6.  **Build and deploy when ready:**
    ```bash
    sudo nixos-rebuild test --flake .#NEW_MACHINE
    # sudo nixos-rebuild switch --flake .#NEW_MACHINE # Use when confident
    ```

### Switching Desktop Environments

Desktop environments are managed via the `desktop` parameter in `self.lib.mkNixosSystem`, enabling easy switching without code duplication. Desktop modules are self-contained and import `modules/nixos/desktop/common.nix` for shared infrastructure.

**Available desktop environments:**
-   `gnome` - GNOME desktop with GDM display manager.
-   `plasma` - KDE Plasma 6 with SDDM display manager.
-   New desktop modules can be added in `modules/nixos/desktop/`.

**To switch desktop on an existing machine (e.g., `centauri`):**

1.  Edit `flake/machines/workstations.nix` or `flake/machines/homelabs.nix`.
2.  Change the `desktop` parameter:
    ```nix
    centauri = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "centauri";
      role = "workstation";
      desktop = "plasma";  # Changed from "gnome" to "plasma"
      modules = [ ... ];
    };
    ```

3.  **Validate the change quickly:**
    ```bash
    nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
    ```

4.  **If validation passes, test and switch:**
    ```bash
    sudo nixos-rebuild test --flake .#centauri
    # sudo nixos-rebuild switch --flake .#centauri  # Use when confident
    ```

**To create a new desktop environment module:**

1.  Create `modules/nixos/desktop/my-de.nix` with the necessary configuration:
    ```nix
    { config, lib, pkgs, ... }: {
      imports = [ ./common.nix ];
      services.xserver.desktopManager.myDE.enable = true;
      # Add other DE-specific configuration here
      # environment.systemPackages = with pkgs; [ my-de-session ];
    }
    ```

2.  Then use it in any machine definition by setting `desktop = "my-de";`.

### Adding a New Module

#### NixOS Module (Service, Desktop Environment, etc.)

1.  **Create in an appropriate category** under `modules/nixos/`:
    ```bash
    # For a new service:
    nano modules/nixos/services/my-new-service.nix

    # For a new desktop environment:
    nano modules/nixos/desktop/my-new-desktop.nix
    ```

2.  **Ensure the module is self-contained.** A self-contained module includes **everything** required for its feature:
    -   Service/application configuration.
    -   Related packages.
    -   User groups and permissions.
    -   Firewall rules (if applicable).
    -   Environment variables.
    -   File permissions.
    -   Kernel parameters.

    ```nix
    { config, lib, pkgs, ... }:
    {
      # My New Service
      # Description: This module provides configuration for MyNewService.
      # It handles the service daemon, related packages, and necessary firewall rules.

      services.my-new-service = {
        enable = true;
        port = 8080;
        # ... other service-specific configuration ...
      };

      # Include ALL related configuration here
      networking.firewall.allowedTCPPorts = [ 8080 ];
      users.users.djoolz.extraGroups = [ "my-new-service-group" ];

      environment.systemPackages = with pkgs; [
        my-new-service-cli-tool
        # ... other related tools ...
      ];
    }
    ```

    **Module isolation - what NOT to do:**
    ```nix
    # ❌ WRONG: Service config in one file, related user group config in another.
    # This creates hidden dependencies and makes the system harder to understand.
    ```

3.  **Import the module** where it's needed:
    -   In `nixos/machines/{hostname}/default.nix` for machine-specific modules.
    -   In `flake/machines/*.nix` for modules shared by role.
    -   In `modules/nixos/roles/{role}.nix` for all machines with that role.
    -   In `flake/homes/profiles/{profile}.nix` for home-manager modules (if applicable).

4.  **Test module independence:**
    ```bash
    nix eval .#nixosConfigurations.centauri.config.services.my-new-service.enable
    ```

#### Home-Manager Module

1.  **Create in appropriate category** under `modules/home/`:
    ```bash
    nano modules/home/programs/my-new-program.nix
    ```

2.  **Import in the relevant home-manager profile** (e.g., `flake/homes/profiles/common.nix` for all profiles, or `flake/homes/profiles/desktop.nix` for GUI-enabled profiles).

### Module Boundaries & When to Split/Combine

**Single concern principle:**
-   Each module should perform one function effectively.
-   A module file should be concise and easily understandable.
-   Consider splitting a module if it exceeds ~100 lines and covers multiple distinct concerns.

**When to keep together (single module):**
-   A service and its associated firewall rules.
-   A service and its required user groups.
-   Closely related configuration for a single, well-defined feature.

**When to split (separate modules):**
-   Different services that operate independently (e.g., `docker.nix` and `tailscale.nix`).
-   Distinct desktop environments (e.g., `gnome.nix` and `plasma.nix`).
-   System-level configuration categories (e.g., `locale.nix` and `shell.nix`).

### Modifying an Existing Module

1.  **Locate the module** by following the directory structure.
2.  **Edit the module file** directly.
3.  **Validate changes quickly** using `nix eval`:
    ```bash
    nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
    ```
4.  **Test on a machine** with `nixos-rebuild test`.

## Best Practices (DOs)

### Configuration

-   ✅ **DO** use `nix eval` for rapid iteration during development.
-   ✅ **DO** validate with `nix flake check` before committing.
-   ✅ **DO** make modules self-contained (all related config in one file).
-   ✅ **DO** add descriptive comments to each module explaining its purpose.
-   ✅ **DO** use role profiles for shared configuration across machines.
-   ✅ **DO** keep machine-specific configuration in `nixos/machines/{hostname}/`.
-   ✅ **DO** use `pkgs-unstable` for packages requiring newer versions.
-   ✅ **DO** consider exporting reusable modules for other flakes.
-   ✅ **DO** use standalone home-manager for user configurations.
-   ✅ **DO** test changes with `nixos-rebuild test` before switching.
-   ✅ **DO** commit after each successful validation.
-   ✅ **DO** use `lib.mkDefault` for role defaults that machines can override.

### Module Organization

-   ✅ **DO** place desktop environments in `modules/nixos/desktop/`.
-   ✅ **DO** place virtualization configurations in `modules/nixos/virtualisation/`.
-   ✅ **DO** place services in `modules/nixos/services/`.
-   ✅ **DO** place core system configurations in `modules/nixos/system/`.
-   ✅ **DO** use roles for common machine profiles.
-   ✅ **DO** make imports explicit (avoid recursive discovery).

### Security

-   ✅ **DO** use `agenix` or `sops-nix` for managing secrets securely.
-   ✅ **DO** reference secrets via file paths, never embed them inline.
-   ✅ **DO** keep CPU mitigations enabled (`mitigations=auto`).
-   ✅ **DO** disable password authentication for SSH.
-   ✅ **DO** ensure firewalls are enabled on networked machines (especially homelab).

## Best Practices (DON'Ts)

### Configuration

-   ❌ **DON'T** use `nixos-rebuild switch` for validation (it's too slow).
-   ❌ **DON'T** use `nix build` during development (prefer `nix eval`).
-   ❌ **DON'T** put shared configuration in machine-specific directories.
-   ❌ **DON'T** duplicate configuration across multiple modules.
-   ❌ **DON'T** use recursive imports (they obscure dependencies).
-   ❌ **DON'T** import machine configurations from other machines.
-   ❌ **DON'T** hardcode values that should be passed via `specialArgs`.
-   ❌ **DON'T** mix NixOS system configuration with home-manager configuration in the same file.
-   ❌ **DON'T** create circular dependencies between modules.
-   ❌ **DON'T** use `lib.mkForce` unless absolutely necessary, as it often indicates a design flaw.

### Module Organization

-   ❌ **DON'T** place modules in `machines/common/` (use `modules/nixos/` instead).
-   ❌ **DON'T** create deeply nested module hierarchies (keep them relatively flat).
-   ❌ **DON'T** put machine-specific configuration in shared modules.
-   ❌ **DON'T** create "god modules" that attempt to manage everything (maintain focus).
-   ❌ **DON'T** mix concerns (e.g., networking and virtualization in one module).
-   ❌ **DON'T** split closely related configuration across multiple files.
-   ❌ **DON'T** assume hidden dependencies (a module should contain everything it needs).
-   ❌ **DON'T** require users to import multiple files for a single feature (modules should be standalone).

### Security

-   ❌ **DON'T** commit secrets directly to git (always use secrets management solutions).
-   ❌ **DON'T** disable security features without thorough documentation and justification.
-   ❌ **DON'T** use `mitigations=off` on networked machines.
-   ❌ **DON'T** enable password authentication for SSH.
-   ❌ **DON'T** disable the firewall without an explicit and strong reason.

## Critical Security Issues

### Secrets Management

**NEVER commit secrets directly to git.** Always use proper secrets management tools:

-   Utilize `agenix` (already listed in inputs) or `sops-nix` for encrypting sensitive data.
-   Reference secrets via file paths (e.g., `/run/secrets/my-secret`).
-   Add secret files to `.gitignore`.
-   Rotate any secrets that may have been accidentally committed.

Example using `agenix`:
```nix
# In a machine configuration:
age.secrets.my-secret.file = ../../secrets/my-secret.age;

# In a service configuration, referencing the secret:
services.myservice.passwordFile = config.age.secrets.my-secret.path;
```

### CPU Mitigations

The file `nixos/machines/centauri/bootloader.nix` may contain `boot.kernelParams = [ "mitigations=off" ];`, which disables Spectre/Meltdown mitigations.

-   This is only acceptable for air-gapped machines.
-   For networked machines, this parameter should be removed or set to `mitigations=auto`.
-   If `mitigations=off` is used for performance reasons, ensure it is thoroughly documented and justified.

## Known Issues & Workarounds

### Powertop Service Crashes on Boot

-   **Location:** `modules/nixos/system/powermanagement.nix`
-   **Issue:** The `powertop` service frequently coredumps on boot but is configured to restart automatically.
-   **Debugging:** Use `journalctl -u powertop -n 50` to inspect logs.
-   **Workaround:** The current configuration tolerates the crash and restarts. Consider switching to `tlp` if this issue becomes problematic.

### Auto-Upgrade Disabled

-   **Location:** `modules/nixos/system/autoupgrade.nix` (currently commented out).
-   **Reason:** Persistent root permission issues prevent reliable automatic upgrades.
-   **Impact:** Requires manual upgrades using `nix flake update && sudo nixos-rebuild switch --flake .#hostname`.

### Dconf Settings (GNOME)

-   **Location:** `modules/home/dconf/dconf.nix`
-   **Nature:** This file is typically auto-generated by `dconf2nix`.
-   **Fragility:** Manual edits to this large, auto-generated file can be lost upon regeneration.
-   **Best practice:**
    -   Export only specific changed sections (e.g., `dconf dump /org/gnome/desktop/interface/ | dconf2nix`).
    -   Manually merge these changes into the existing `dconf.nix`.
    -   Never regenerate the entire file without backing up manual modifications.

## Testing Strategy

### Fast Iteration Loop (Primary)

This workflow is crucial for efficient development and quick feedback.

```bash
# 1. Make changes to modules, configurations, or packages.

# 2. Perform fast validation (each command should execute in <1 second):
nix flake check                                          # Check flake structure and syntax
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel  # Evaluate a specific machine's config

# 3. Check if specific configuration settings are correctly propagated:
nix eval .#nixosConfigurations.centauri.config.services.xserver.enable
nix eval .#nixosConfigurations.centauri.config.networking.hostName

# 4. Only if all evaluations pass, proceed to slower build testing.
```

### Build Testing (When Evals Pass)

Once fast validation is successful, use these commands for more comprehensive testing.

```bash
# 1. Perform a dry run (shows what changes would occur without applying them, faster than full build):
sudo nixos-rebuild dry-build --flake .#centauri

# 2. Test the configuration without modifying the bootloader (safe to revert):
sudo nixos-rebuild test --flake .#centauri

# 3. When confident that the changes are correct and stable, switch permanently:
sudo nixos-rebuild switch --flake .#centauri
```

### Validation Script

For comprehensive, automated testing, use the `validate.sh` script:

```bash
./validate.sh  # This script validates all configurations quickly
```

## Git Workflow

### Pre-commit

-   **Auto-formatting:** `treefmt` runs automatically on commit, ensuring consistent code style.
-   **Flake.lock:** Updates to `flake.lock` are automatically staged.
-   **Pre-push hooks:** Configured to prevent unformatted or invalid code from being pushed to the remote repository.

### Commit Strategy

1.  Make desired changes to modules or configurations.
2.  Run `nix eval` commands for quick, iterative validation.
3.  Run `nix flake check` to ensure overall flake integrity.
4.  Commit changes with a descriptive message.
5.  Perform build testing (`nixos-rebuild test`) only when ready to deploy.

### Conventional Commits

Utilize semantic commit messages to clearly communicate the purpose of each change:

-   `feat:`: New feature or module.
-   `fix:`: Bug fix.
-   `refactor:`: Code restructuring without behavior changes.
-   `docs:`: Documentation updates.
-   `chore:`: Routine maintenance tasks.

Example: `feat(modules): add KDE Plasma desktop environment`

## Common Troubleshooting

### "file not found" on evaluation

-   Verify all `imports = [ ... ]` paths are correct relative to the importing file.
-   Confirm file existence: `ls -la modules/nixos/services/MISSING_FILE.nix`.
-   Check for typos in file paths, especially with deep directory structures.

### Module evaluation errors

-   Check if the overall flake structure is valid: `nix flake show`.
-   Parse individual files for syntax errors: `nix-instantiate --parse modules/nixos/desktop/gnome.nix`.
-   Get a detailed evaluation trace: `nix eval --show-trace .#nixosConfigurations.centauri.config.system.build.toplevel`.

### Conflicting module options

-   Look for duplicate imports of the same module.
-   Investigate if `lib.mkForce` is being used to override role defaults inappropriately.
-   Ensure only one desktop environment is enabled.
-   Verify only one virtualization backend (e.g., Docker OR Podman) is active.

### Missing packages after changes

-   Search for the package in the stable channel: `nix search nixpkgs PACKAGE_NAME`.
-   Search in the unstable channel: `nix search nixpkgs#nixpkgs-unstable PACKAGE_NAME`.
-   Check if the package name has changed by reviewing `nixpkgs` release notes for your version.

### Home-manager activation failures

-   Evaluate the home-manager configuration for errors: `nix eval .#homeConfigurations."djoolz@workstation".activationPackage`.
-   Check `home-manager` specific logs: `journalctl --user -u home-manager-djoolz`.
-   Perform a dry-run activation: `home-manager switch --flake .#djoolz@workstation --dry-run`.

### Slow evaluation times

-   Avoid using `--show-trace` unless actively debugging, as it adds significant overhead.
-   Use `nix eval` instead of `nix build` during development.
-   Check for infinite recursion in module imports.
-   Verify there are no circular dependencies between modules.

## Performance Notes

-   **Parallel builds:** Nix automatically utilizes all available CPU cores.
-   **Binary cache:** Configured to use `nix-community.cachix.org` and `hetzner-cache.numtide.com` for faster dependency resolution.
-   **Store optimization:** Automatic optimization is enabled in `modules/nixos/system/nix-settings.nix`.
-   **Garbage collection:** Manual garbage collection can be performed with `nix-collect-garbage -d`.
-   **Fast validation:** Always prioritize `nix eval` for iterative development, only building when deployment is imminent.

## Advanced Topics

### Using This Config in Other Flakes

This configuration exports reusable modules that can be consumed by other flakes:

```nix
{
  inputs.my-config.url = "github:djoolz/nixos-config"; # Replace with actual URL/path

  # Use exported NixOS modules
  imports = [
    inputs.my-config.nixosModules.gnome
    inputs.my-config.nixosModules.tailscale
  ];

  # Use exported Home-Manager modules
  home-manager.users.myuser = {
    imports = [ inputs.my-config.homeModules.desktop ];
  };
}
```

### Remote Deployment

For deploying to remote machines, consider using specialized tools:
-   `deploy-rs` for push-based deployment workflows.
-   `colmena` for managing multiple machines declaratively.
-   `nixos-anywhere` for provisioning new machines.

### CI/CD Integration

Automate validation and checks in your CI/CD pipelines (e.g., GitHub Actions):

```yaml
# .github/workflows/check.yml
jobs:
  nix-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      - name: Check flake
        run: nix flake check
      - name: Evaluate Centauri config
        run: nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
      # Add more evaluation steps for other critical configurations
```

## Migration Notes

**Current Status:** Migration to modular structure is substantially complete (~90%).

-   See `plan.md` for detailed migration history.
-   **Completed:** Role-based machine organization, standalone home-manager, modular services.
-   **Remaining:** Minor cleanup and documentation updates.

Always validate your changes with `nix eval` after any modifications to ensure correctness.
