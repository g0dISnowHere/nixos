# Codebase Structure

**Analysis Date:** 2026-02-04

## Directory Layout

```
/home/djoolz/Documents/01_config/mine/
├── .planning/              # Planning and analysis documents (GSD tool output)
├── .claude/                # Claude AI session data
├── .gemini/                # Gemini AI session data
├── .opencode/              # OpenCode AI session data
├── nixos/                  # All NixOS system and user configurations
│   ├── configurations.nix  # System factory function; entry point for machine setup
│   ├── machines/           # Per-machine NixOS configurations
│   │   ├── centauri/       # Desktop machine (x86_64)
│   │   │   ├── default.nix                    # Aggregates imports for centauri
│   │   │   ├── configuration.nix              # Main system config
│   │   │   ├── bootloader.nix                 # EFI/systemd-boot setup
│   │   │   ├── hardware-configuration.nix     # Auto-generated hardware detection
│   │   │   ├── other-hardware.nix             # Additional hardware modules
│   │   │   ├── networking.nix                 # Network configuration
│   │   │   ├── firewall.nix                   # Firewall rules
│   │   │   └── fingerprints.nix               # SSH host key fingerprints
│   │   ├── mirach/         # Desktop machine (x86_64)
│   │   │   ├── default.nix
│   │   │   ├── configuration.nix
│   │   │   ├── hardware-configuration.nix
│   │   │   └── [optional: networking.nix, firewall.nix, bootloader.nix]
│   │   ├── template/       # Template for new machines
│   │   │   ├── default.nix                    # Contains examples and comments
│   │   │   └── hardware-configuration.nix     # Placeholder
│   │   ├── common/         # Shared system-level modules
│   │   │   ├── android.nix                    # Android SDK/tools setup
│   │   │   ├── autoupgrade.nix                # Automatic system updates & GC
│   │   │   ├── gnome.nix                      # GNOME desktop environment
│   │   │   ├── locale.nix                     # Locale/timezone setup
│   │   │   ├── plasma.nix                     # KDE Plasma alternative to GNOME
│   │   │   ├── powermanagement.nix            # Power saving & sleep profiles
│   │   │   ├── services.nix                   # System services (Flatpak, etc)
│   │   │   ├── shell.nix                      # Shell setup, dev toolchains
│   │   │   ├── ssh.nix                        # SSH daemon configuration
│   │   │   ├── suspend-then-hibernate.nix     # Suspend/hibernate modes
│   │   │   ├── tailscale.nix                  # Tailscale VPN client
│   │   │   └── virtualisation/                # Container/VM platforms
│   │   │       ├── docker.nix                 # Docker with root daemon
│   │   │       ├── docker_rootless.nix        # Docker rootless mode
│   │   │       ├── libvirtd.nix               # KVM/QEMU hypervisor
│   │   │       ├── podman.nix                 # Podman (Docker alternative)
│   │   │       └── quickemu.nix               # Quickemu VM runner
│   │   ├── karakan/        # Scanner machine (special-purpose)
│   │   └── scanner.nix     # Scanner configuration (Canon SANE support)
│   └── users/              # Per-user home-manager configurations
│       ├── djoolz.nix      # Main user config (imports modules)
│       └── modules/        # Home-manager user modules
│           ├── dconf.nix                      # GNOME dconf settings (1038 lines)
│           ├── flatpak.nix                    # Flatpak application packages
│           ├── homeassistant.nix              # Home Assistant integration
│           ├── packages.nix                   # User packages list
│           └── programs.nix                   # Program configurations
├── flake.nix               # Flake declaration; input versions & experimental features
├── flake.lock              # Locked input revisions (reproducibility)
├── outputs.nix             # Flake output definition; delegates to configurations.nix
├── treefmt.nix             # Code formatter configuration
├── README.md               # Project overview
├── prd.md                  # Product requirements/planning doc
├── tasks.md                # Task tracking
├── nixos_configuration_analysis.md # Earlier analysis document
└── [artifact files]        # Kismet logs, SVG visualizations, etc.
```

## Directory Purposes

**nixos/:**
- Purpose: Container for all NixOS and home-manager configurations
- Contains: System configs (machines/), user configs (users/), system factory (configurations.nix)
- Key files: `configurations.nix` (factory), `machines/*/default.nix` (machine entry points), `users/djoolz.nix` (user entry point)

**nixos/machines/:**
- Purpose: Machine-specific configurations
- Contains: Per-hostname subdirectories (centauri, mirach, karakan, template)
- Key files: `*/default.nix` (aggregates machine imports), `*/configuration.nix` (main config)

**nixos/machines/{hostname}/:**
- Purpose: All configuration for a single machine
- Contains: Hardware detection, bootloader, services, networking, firewall specific to this machine
- Key files:
  - `default.nix`: Aggregates `bootloader.nix`, `configuration.nix`, `hardware-configuration.nix`, optional networking/firewall
  - `configuration.nix`: Main system config; imports common modules (GNOME, services, virtualisation)
  - `hardware-configuration.nix`: Auto-generated via `nixos-generate-config`; DO NOT edit manually

**nixos/machines/common/:**
- Purpose: Shared system-level modules; imported by individual machines
- Contains: Desktop environments (GNOME/KDE), network services (Tailscale, SSH), containerization (Docker/Podman)
- Usage pattern: Individual machine `configuration.nix` imports relevant modules via `imports = [ ../common/gnome.nix ../common/services.nix ... ]`
- Example: `centauri/configuration.nix` lines 8-24 imports ~10 common modules

**nixos/machines/common/virtualisation/:**
- Purpose: Container/VM platform choices
- Contains: Docker (root & rootless), Podman, Libvirtd, Quickemu
- Usage: Machines selectively import based on workload
- Example: `centauri/configuration.nix` line 20 enables docker_rootless; line 21-23 have libvirtd/podman commented out

**nixos/users/:**
- Purpose: Per-user configurations managed by home-manager
- Contains: Main user config (djoolz.nix) and feature modules
- Key files: `djoolz.nix` (entry point; imports modules), `modules/` (packages, programs, services)

**nixos/users/modules/:**
- Purpose: Modular home-manager configuration; home-manager equivalent of `machines/common/`
- Contains:
  - `packages.nix`: home.packages list (fonts, CLI tools, development toolchains, utilities)
  - `programs.nix`: Program configurations (shell config, editor settings, etc)
  - `dconf.nix`: GNOME dconf database settings; largest module (1038 lines)
  - `flatpak.nix`: Flatpak application packages
  - `homeassistant.nix`: Home Assistant service configuration
- Usage: Selectively enabled via comments in `djoolz.nix` imports
- Example: `djoolz.nix` lines 16-22 imports packages, programs, and quickemu; flatpak is commented out

**Root level:**
- Purpose: Flake metadata and project documentation
- Key files:
  - `flake.nix`: Declares inputs (nixpkgs versions, home-manager, nix-flatpak, etc); triggers `outputs.nix`
  - `outputs.nix`: Flake outputs; calls `configurations.nix` to build all machines
  - `flake.lock`: Exact revisions of all inputs; commit to git for reproducibility
  - `treefmt.nix`: Nix code formatter configuration

## Key File Locations

**Entry Points:**

- `flake.nix`: Root flake entry; declares inputs and delegates to outputs.nix
  - Purpose: Defines what external inputs (nixpkgs, home-manager) are needed and from where
  - Used by: `nix flake` commands, `nixos-rebuild --flake`

- `outputs.nix`: Flake outputs definition; imports configurations.nix
  - Purpose: Orchestrates build outputs (nixosConfigurations, devShells)
  - Used by: flake.nix line 43 via `import ./outputs.nix args`

- `nixos/configurations.nix`: System factory and machine definitions
  - Purpose: Instantiates mkNixosSystem for each machine
  - Used by: outputs.nix line 47 via `import ./nixos/configurations.nix inputs`

- `nixos/machines/{hostname}/default.nix`: Per-machine entry
  - Purpose: Aggregates machine-specific configuration imports
  - Used by: configurations.nix line 14 via `./machines/${hostname}`

- `nixos/users/djoolz.nix`: User configuration entry
  - Purpose: Defines user environment via home-manager
  - Used by: configurations.nix line 23 via `import ./users/djoolz.nix`

**Configuration:**

- `flake.lock`: Locked input revisions
  - Tracks exact git commit hashes for reproducible builds
  - Update via `nix flake update`

- `treefmt.nix`: Code formatter config
  - Specifies nixpkgs-fmt, statix (linter), deadnix (unused detection)

**Core Logic:**

- `nixos/machines/common/shell.nix`: Development environment setup
  - Contains: Python toolchains, Go, Node.js, Rust, shell configuration
  - Imported by: `centauri/configuration.nix` line 17

- `nixos/machines/common/services.nix`: System services
  - Contains: Flatpak packages, syncthing, other services
  - Imported by: `centauri/configuration.nix` line 15

- `nixos/machines/common/gnome.nix`: GNOME desktop environment
  - Contains: GDM display manager, GNOME packages and extensions
  - Imported by: `centauri/configuration.nix` line 11

- `nixos/users/modules/packages.nix`: User packages
  - Contains: ~155 lines of fonts, utilities, dev tools
  - Imported by: `djoolz.nix` line 18

- `nixos/users/modules/dconf.nix`: GNOME settings database
  - Contains: 1038 lines of dconf settings (keybindings, appearance, etc)
  - Imported indirectly or via `djoolz.nix`

**Testing:**

- No unit/integration test framework detected
- Configuration validation happens at `nixos-rebuild switch` time (Nix evaluation)

## Naming Conventions

**Files:**

- Lowercase with underscores for multi-word: `docker_rootless.nix`, `suspend_then_hibernate.nix`
- File extension always `.nix`
- Generic/non-machine-specific modules: `common/{feature}.nix`
- Machine-specific configs: `machines/{hostname}/{aspect}.nix`
- User modules: `users/modules/{feature}.nix`

**Directories:**

- Lowercase: `nixos/`, `machines/`, `users/`, `modules/`, `virtualisation/`
- Descriptive names matching content: `common/`, `template/`
- Plural for collections: `machines/`, `users/`, `modules/`
- Singular for namespaces: `virtualisation/` (contains docker, podman, etc)

**Configuration Attributes:**

- Nix expressions use camelCase: `home.packages`, `services.flatpak.enable`, `environment.systemPackages`
- These follow NixOS module system conventions, not this project's choice

## Where to Add New Code

**New Machine:**

1. Copy `nixos/machines/template/` to `nixos/machines/{newhostname}/`
2. Edit `default.nix`:
   - Uncomment/modify relevant imports (bootloader, networking, firewall)
   - Ensure `hardware-configuration.nix` exists
3. Run `nixos-generate-config --root /mnt --show-hardware-config > nixos/machines/{newhostname}/hardware-configuration.nix` during install
4. Add instantiation to `nixos/configurations.nix`:
   ```nix
   {newhostname} = mkNixosSystem {
     system = "x86_64-linux";  # or "aarch64-linux" for ARM
     hostname = "{newhostname}";
     modules = [ ];
   };
   ```
5. Deploy: `nixos-rebuild switch --flake .#{newhostname}`

**New System Service/Module:**

1. Create `nixos/machines/common/{feature}.nix`:
   ```nix
   { config, pkgs, lib, ... }: {
     # Configuration here
   }
   ```
2. Import in machine `configuration.nix`:
   ```nix
   imports = [
     ../common/{feature}.nix
   ];
   ```
   Or conditionally in `default.nix` if machine-specific.

**New User Package/Program:**

1. Add to existing module or create `nixos/users/modules/{feature}.nix`
2. Add package to `nixos/users/modules/packages.nix` home.packages list:
   ```nix
   home.packages = with pkgs; [
     # existing packages
     newpackage
   ];
   ```
   Or for programs with configuration, create new module in `modules/`
3. Import in `nixos/users/djoolz.nix`:
   ```nix
   imports = [
     ./modules/{feature}.nix
   ];
   ```

**New Common Hardware/Virtualisation Option:**

1. Create `nixos/machines/common/{new-option}.nix` (following patterns of docker.nix, libvirtd.nix)
2. Machine `configuration.nix` can selectively import:
   ```nix
   imports = [
     ../common/{new-option}.nix
   ];
   ```

**Example: Add Podman to Centauri:**

1. Uncomment in `nixos/machines/centauri/configuration.nix`:
   ```nix
   ../common/virtualisation/podman.nix
   ```
2. Run: `nixos-rebuild switch --flake .#centauri`

## Special Directories

**`.planning/codebase/`:**
- Purpose: GSD tool output; architecture/structure analysis documents
- Generated: Yes (by GSD mapping tool)
- Committed: Recommend yes (for reference)
- Contents: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, CONCERNS.md

**`.claude/`, `.gemini/`, `.opencode/`:**
- Purpose: AI session data/context storage
- Generated: Yes (by respective AI tools)
- Committed: Usually no (add to .gitignore)
- Contents: Conversation history and context

**`flake.lock`:**
- Purpose: Reproducibility lock file
- Generated: Yes (by `nix flake update` or `nix flake check`)
- Committed: Yes (always)
- Contents: Exact git revisions of all inputs

---

*Structure analysis: 2026-02-04*
