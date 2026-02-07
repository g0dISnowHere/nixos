# NixOS Flake Refactoring Plan

## Overview

Refactor the current NixOS configuration to use flake-parts with modular, self-contained components. Separate concerns by role (workstation, homelab), decouple home-manager from machines, and extract services/functionality into reusable modules.

## Design Principles

1. **Explicit imports** - No recursive discovery, clear dependencies
2. **Role-based organization** - Workstations vs homelabs clearly separated
3. **Self-contained modules** - Each service/feature is independent
4. **Standalone home-manager** - Users decoupled from machines
5. **Reusable modules** - Easy to export for other flakes
6. **Preserve everything** - Keep all commented code and functionality

## Current State

```
mine/
├── flake.nix                          # Inputs + delegates to outputs.nix
├── outputs.nix                        # flake-parts setup with inline configs
├── treefmt.nix                        # Formatter configuration
└── nixos/
    ├── configurations.nix             # Machine factory with mkNixosSystem
    ├── machines/
    │   ├── common/                    # Shared modules (mixed concerns)
    │   ├── centauri/                  # Laptop/workstation
    │   ├── mirach/                    # Homelab server
    │   ├── karakan/
    │   └── template/
    └── users/
        └── djoolz.nix                 # Tightly coupled to machines
```

## Target State

```
mine/
├── flake.nix                          # Input declarations only
├── outputs.nix                        # Minimal orchestrator (imports only)
│
├── parts/                             # Flake-parts perSystem modules
│   ├── systems.nix                    # Supported architectures
│   ├── devshells.nix                  # Development environments
│   ├── formatter.nix                  # Treefmt configuration
│   ├── packages.nix                   # Custom packages (empty now)
│   └── checks.nix                     # CI checks (empty now)
│
├── flake/                             # Flake-level outputs
│   ├── machines/                      # Machine definitions by role
│   │   ├── workstations.nix           # Centauri and similar
│   │   └── homelabs.nix               # Mirach and similar
│   ├── homes/                         # Standalone home-manager
│   │   ├── djoolz.nix                 # User-specific config
│   │   └── profiles/                  # Reusable home profiles
│   │       ├── common.nix             # Base CLI profile
│   │       ├── desktop.nix            # GUI apps + dconf
│   │       └── development.nix        # Dev tools (future)
│   ├── modules.nix                    # Exported nixosModules/homeModules
│   └── lib.nix                        # Helper functions (mkNixosSystem)
│
├── modules/                           # NixOS & Home modules
│   ├── nixos/                         # System-level modules
│   │   ├── desktop/                   # Desktop environments
│   │   │   ├── gnome.nix              # GNOME setup
│   │   │   └── plasma.nix             # KDE Plasma
│   │   ├── virtualisation/            # Virtualization options
│   │   │   ├── libvirtd.nix           # KVM/QEMU
│   │   │   ├── docker.nix             # Docker
│   │   │   ├── docker-rootless.nix    # Rootless Docker
│   │   │   ├── podman.nix             # Podman
│   │   │   └── quickemu.nix           # QuickEMU
│   │   ├── services/                  # System services
│   │   │   ├── tailscale.nix          # Tailscale VPN
│   │   │   ├── ssh.nix                # SSH daemon
│   │   │   ├── android.nix            # Android support
│   │   │   └── homeassistant.nix      # Home Assistant
│   │   ├── system/                    # System configuration
│   │   │   ├── locale.nix             # Localization
│   │   │   ├── shell.nix              # Shell defaults
│   │   │   ├── powermanagement.nix    # Power settings
│   │   │   ├── autoupgrade.nix        # Auto-upgrade
│   │   │   ├── suspend-then-hibernate.nix
│   │   │   ├── nix-settings.nix       # Nix daemon config
│   │   │   └── services.nix           # Common services
│   │   └── roles/                     # Role profiles
│   │       ├── workstation.nix        # Workstation defaults
│   │       └── homelab.nix            # Server defaults
│   └── home/                          # Home-manager modules
│       ├── programs/                  # Program configurations
│       ├── packages/                  # Package lists
│       └── dconf/                     # GNOME/dconf settings
│
└── machines/                          # Machine-specific configs
    ├── centauri/                      # Laptop/workstation
    │   ├── default.nix                # Imports role + overrides
    │   ├── hardware-configuration.nix # Hardware scan
    │   ├── bootloader.nix             # Boot config
    │   └── other-hardware.nix         # Additional hardware
    └── mirach/                        # Homelab server
        ├── default.nix                # Imports role + overrides
        ├── hardware-configuration.nix # Hardware scan
        └── services/                  # Machine-specific services
            └── homeassistant.nix      # HA VM config
```

## Implementation Plan

### Phase 1: Create Infrastructure (No Breaking Changes)

**Goal:** Set up new directory structure without breaking existing configs

#### 1.1 Create `parts/` directory

```bash
mkdir -p parts
```

**Create `parts/systems.nix`:**
```nix
{
  # Supported system architectures for perSystem evaluation
  # Used by flake-parts to generate per-system outputs
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    # "aarch64-darwin"  # Uncomment for macOS support
    # "x86_64-darwin"
  ];
}
```

**Create `parts/devshells.nix`:**
```nix
{ inputs, ... }:
{
  perSystem = { pkgs, system, ... }: {
    # Development environment for this flake
    # Available via: nix develop
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nixpkgs-fmt  # Nix code formatter
        statix       # Nix linter for best practices
        deadnix      # Dead code detection
      ];

      shellHook = ''
        echo "NixOS configuration development environment"
        echo "Current system: ${system}"
      '';
    };
  };
}
```

**Create `parts/formatter.nix`:**
```bash
# Move treefmt.nix to parts/formatter.nix
mv treefmt.nix parts/formatter.nix
```

Update import path reference in the file:
```nix
{ inputs, ... }: {
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = { config, self', inputs', pkgs, system, ... }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt = {
          enable = pkgs.lib.meta.availableOn pkgs.stdenv.buildPlatform
            pkgs.nixfmt-rfc-style.compiler;
          package = pkgs.nixfmt-classic;
        };
        yamlfmt.enable = true;
        black.enable = true;
      };

      settings.global.excludes = [
        "machines/*/facts/*"
        "old-machines/*/facts/*"
        "vars/*"
        "*.gpg"
        "*.pub"
        ".git-crypt/*"
        "*.png"
        "LICENSE"
        "*.gitignore"
        ".gitattributes"
      ];
    };
  };
}
```

**Create `parts/packages.nix`:**
```nix
{ inputs, ... }:
{
  # Custom packages
  # Currently empty - will be populated as needed
  perSystem = { pkgs, ... }: {
    packages = {
      # Example:
      # my-tool = pkgs.callPackage ./pkgs/my-tool {};
    };
  };
}
```

**Create `parts/checks.nix`:**
```nix
{ inputs, ... }:
{
  # CI checks and validations
  # Currently empty - will be populated with tests
  perSystem = { pkgs, ... }: {
    checks = {
      # Example:
      # treefmt = config.treefmt.build.check;
    };
  };
}
```

#### 1.2 Create `flake/` directory

```bash
mkdir -p flake/machines flake/homes/profiles
```

**Create `flake/lib.nix`:**
```nix
{ inputs, ... }:
let
  inherit (inputs) nixpkgs home-manager nix-flatpak nixpkgs-unstable nixpkgs-tailscale;
in
{
  flake.lib = {
    # Helper function to create a NixOS system configuration
    # Provides consistent setup for all machines with role-based defaults
    mkNixosSystem = { system, hostname, role, modules ? [], extraSpecialArgs ? {} }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Machine-specific hardware and config
          ../machines/${hostname}

          # Role-based defaults (workstation, homelab, etc.)
          ../modules/nixos/roles/${role}.nix

          # Home-manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              # Note: Individual machines set home-manager.users.*
              # in their default.nix to reference profile modules
              extraSpecialArgs = {
                pkgs-unstable = import nixpkgs-unstable {
                  inherit system;
                  config.allowUnfree = true;
                };
              };
            };
          }

          # Flatpak support
          nix-flatpak.nixosModules.nix-flatpak

          # Global Nix daemon settings
          ../modules/nixos/system/nix-settings.nix
        ] ++ modules;

        specialArgs = {
          inherit inputs hostname;
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-tailscale = import nixpkgs-tailscale {
            inherit system;
            config.allowUnfree = true;
          };
        } // extraSpecialArgs;
      };
  };
}
```

#### 1.3 Validation

```bash
# Quick validation - these should all pass
nix flake check
nix flake show
nix develop --command echo "✓ Dev shell accessible"

# Verify existing configs still evaluate
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel
```

### Phase 2: Extract and Organize NixOS Modules

**Goal:** Move common modules into organized, self-contained structure

#### 2.1 Create module directory structure

```bash
mkdir -p modules/nixos/{desktop,virtualisation,services,system,roles}
mkdir -p modules/home/{programs,packages,dconf}
```

#### 2.2 Move desktop environments

```bash
mv nixos/machines/common/gnome.nix modules/nixos/desktop/
mv nixos/machines/common/plasma.nix modules/nixos/desktop/
```

Update `modules/nixos/desktop/gnome.nix` to be self-documenting:
```nix
{ config, lib, pkgs, ... }:
{
  # GNOME Desktop Environment
  # Provides full GNOME experience with GDM, core apps, and extensions

  # Enable GNOME desktop
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # ... rest of existing gnome.nix content ...
}
```

Do the same for `plasma.nix`.

#### 2.3 Move virtualisation modules

```bash
mv nixos/machines/common/virtualisation/libvirtd.nix modules/nixos/virtualisation/
mv nixos/machines/common/virtualisation/docker.nix modules/nixos/virtualisation/
mv nixos/machines/common/virtualisation/docker_rootless.nix modules/nixos/virtualisation/
mv nixos/machines/common/virtualisation/podman.nix modules/nixos/virtualisation/
mv nixos/machines/common/virtualisation/quickemu.nix modules/nixos/virtualisation/
```

Add header comments to each explaining what it provides.

#### 2.4 Move services

```bash
mv nixos/machines/common/tailscale.nix modules/nixos/services/
mv nixos/machines/common/ssh.nix modules/nixos/services/
mv nixos/machines/common/android.nix modules/nixos/services/
mv nixos/machines/common/services.nix modules/nixos/system/
```

#### 2.5 Move system configuration

```bash
mv nixos/machines/common/locale.nix modules/nixos/system/
mv nixos/machines/common/shell.nix modules/nixos/system/
mv nixos/machines/common/powermanagement.nix modules/nixos/system/
mv nixos/machines/common/autoupgrade.nix modules/nixos/system/
mv nixos/machines/common/suspend-then-hibernate.nix modules/nixos/system/
```

#### 2.6 Extract global Nix settings

**Create `modules/nixos/system/nix-settings.nix`:**

Extract from `nixos/configurations.nix` lines 36-60:
```nix
{ config, lib, pkgs, ... }:
{
  # Global Nix daemon configuration
  # Applies to all machines

  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    settings = {
      trusted-users = [ "djoolz" ];

      keep-outputs = false; # remove old derivations
      keep-derivations = false; # remove old derivations

      fallback = true;
      warn-dirty = false;
      auto-optimise-store = true;

      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://hetzner-cache.numtide.com"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      ];
    };
  };
}
```

#### 2.7 Validation

```bash
# Files should exist in new locations
ls -la modules/nixos/desktop/
ls -la modules/nixos/virtualisation/
ls -la modules/nixos/services/
ls -la modules/nixos/system/

# Existing configs should still evaluate (not using new modules yet)
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel
```

### Phase 3: Create Role Profiles

**Goal:** Define role-based default configurations

#### 3.1 Create workstation role

**Create `modules/nixos/roles/workstation.nix`:**
```nix
{ config, lib, pkgs, ... }:
{
  # Workstation Role Profile
  # Interactive desktop machine for development and daily use
  #
  # Provides:
  # - Desktop environment (imported by machine)
  # - Audio/video support
  # - Networking with NetworkManager
  # - Printing and Bluetooth
  # - Power management for laptops

  imports = [
    # System essentials
    ../system/locale.nix
    ../system/shell.nix
    ../system/powermanagement.nix
    ../system/services.nix

    # Services
    ../services/tailscale.nix

    # Note: Desktop environment and virtualization are imported
    # by individual machines based on their needs
  ];

  # Networking
  networking.networkmanager.enable = true;

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = false;
  };

  # Printing
  services.printing.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable CUPS for printer discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
```

#### 3.2 Create homelab role

**Create `modules/nixos/roles/homelab.nix`:**
```nix
{ config, lib, pkgs, ... }:
{
  # Homelab Role Profile
  # Server/homelab machine with optional GUI for management
  #
  # Provides:
  # - SSH server with secure defaults
  # - Tailscale for remote access
  # - Networking with NetworkManager
  # - Firewall enabled by default
  # - Optional desktop environment (imported by machine)

  imports = [
    # System essentials
    ../system/locale.nix
    ../system/shell.nix
    ../system/services.nix

    # Services
    ../services/ssh.nix
    ../services/tailscale.nix

    # Note: Desktop environment (for management), virtualization,
    # and machine-specific services are imported by the machine config
  ];

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # SSH with secure defaults
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Optional: Audio for machines with GUI
  # Enabled by default, can be disabled in machine config
  security.rtkit.enable = lib.mkDefault true;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };
}
```

#### 3.3 Validation

```bash
# Verify files exist
ls -la modules/nixos/roles/

# Check syntax
nix-instantiate --parse modules/nixos/roles/workstation.nix
nix-instantiate --parse modules/nixos/roles/homelab.nix
```

### Phase 4: Separate Home-Manager from Machines

**Goal:** Create standalone home-manager configurations decoupled from machines

#### 4.1 Move existing user modules to new structure

```bash
# Create structure for user modules
mkdir -p modules/home/programs
mkdir -p modules/home/packages
mkdir -p modules/home/dconf

# Move existing user config components
# (Assuming nixos/users/djoolz.nix imports modules from nixos/users/modules/)
# These will be split into the new structure
```

#### 4.2 Create home profile: common

**Create `flake/homes/profiles/common.nix`:**
```nix
{ config, pkgs, pkgs-unstable, ... }:
{
  # Common home-manager configuration
  # Shared across all profiles - provides CLI essentials
  # Use this profile for headless servers

  imports = [
    # Import user modules (programs, packages, etc.)
    # These will be populated from existing nixos/users/modules/
    # ../../../modules/home/programs
    # ../../../modules/home/packages
  ];

  # Basic home configuration
  home.stateVersion = "25.11";

  # Enable home-manager
  programs.home-manager.enable = true;

  # Basic packages every profile needs
  home.packages = with pkgs; [
    # CLI essentials
    vim
    git
    htop
  ];
}
```

#### 4.3 Create home profile: desktop

**Create `flake/homes/profiles/desktop.nix`:**
```nix
{ config, pkgs, pkgs-unstable, ... }:
{
  # Desktop profile
  # Extends common profile with GUI applications and GNOME settings
  # Use this profile for workstations and GUI-enabled machines

  imports = [
    ./common.nix
    # Import dconf settings (GNOME configuration)
    # ../../../modules/home/dconf
  ];

  # Desktop-specific packages
  home.packages = with pkgs; [
    # GUI applications
    firefox
    thunderbird
    # ... more from existing user config ...
  ];

  # Desktop-specific program configurations
  # programs.firefox.enable = true;
  # ... etc ...
}
```

#### 4.4 Create standalone home-manager configurations

**Create `flake/homes/djoolz.nix`:**
```nix
{ inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake.homeConfigurations = {
    # Standalone home-manager config for djoolz@workstation
    # Usage: home-manager switch --flake .#djoolz@workstation
    "djoolz@workstation" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

      extraSpecialArgs = {
        pkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      modules = [
        ./profiles/desktop.nix
        {
          home.username = "djoolz";
          home.homeDirectory = "/home/djoolz";
        }
      ];
    };

    # CLI-only profile for servers
    # Usage: home-manager switch --flake .#djoolz@server
    "djoolz@server" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

      extraSpecialArgs = {
        pkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      modules = [
        ./profiles/common.nix
        {
          home.username = "djoolz";
          home.homeDirectory = "/home/djoolz";
        }
      ];
    };
  };
}
```

#### 4.5 Validation

```bash
# Verify structure
ls -la flake/homes/profiles/

# Evaluate home configurations
nix eval .#homeConfigurations."djoolz@workstation".activationPackage
nix eval .#homeConfigurations."djoolz@server".activationPackage
```

### Phase 5: Refactor Machine Definitions

**Goal:** Use new role-based structure and lib.mkNixosSystem

#### 5.1 Create machine configuration modules

**Create `flake/machines/workstations.nix`:**
```nix
{ self, inputs, ... }:
{
  flake.nixosConfigurations = {
    # Centauri - Primary laptop/workstation
    centauri = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "centauri";
      role = "workstation";
      modules = [
        # Desktop environment
        ../modules/nixos/desktop/gnome.nix

        # Virtualization
        ../modules/nixos/virtualisation/docker-rootless.nix

        # Machine-specific overrides happen in machines/centauri/default.nix
      ];
    };

    # Add more workstations here as needed
  };
}
```

**Create `flake/machines/homelabs.nix`:**
```nix
{ self, inputs, ... }:
{
  flake.nixosConfigurations = {
    # Mirach - Homelab server with GUI for management
    # Runs Home Assistant VM and Docker services
    mirach = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "mirach";
      role = "homelab";
      modules = [
        # GUI for management
        ../modules/nixos/desktop/gnome.nix

        # Virtualization for Home Assistant VM
        ../modules/nixos/virtualisation/libvirtd.nix

        # Docker for services
        ../modules/nixos/virtualisation/docker.nix

        # Machine-specific services in machines/mirach/
      ];
    };

    # Add more homelabs here as needed
  };
}
```

#### 5.2 Update machine-specific configs

**Update `machines/centauri/default.nix`:**
```nix
{ config, pkgs, hostname, ... }:
{
  # Centauri - Primary laptop/workstation
  # Hardware: [describe hardware]
  # Role: Workstation (development, daily use)

  imports = [
    ./hardware-configuration.nix
    ./bootloader.nix
    ./other-hardware.nix
  ];

  # Hostname
  networking.hostName = hostname;

  # User configuration
  users.users.djoolz = {
    isNormalUser = true;
    description = "djoolz";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  # Home-manager configuration for this machine
  # References the desktop profile (GUI + dev tools)
  home-manager.users.djoolz = import ../../flake/homes/profiles/desktop.nix;

  # AppImage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # dconf settings (machine-specific overrides)
  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          # clock-show-weekday = true;
        };
      };
    }];
  };

  # Machine-specific packages
  environment.systemPackages = with pkgs; [
    # Add machine-specific tools here
  ];

  system.stateVersion = "25.11";
}
```

**Update `machines/mirach/default.nix`:**
```nix
{ config, pkgs, hostname, ... }:
{
  # Mirach - Homelab server
  # Hardware: [describe hardware]
  # Role: Homelab (VMs, Docker services, Home Assistant)

  imports = [
    ./hardware-configuration.nix
    ./services/homeassistant.nix  # If exists
    # Add other machine-specific service configs
  ];

  # Hostname
  networking.hostName = hostname;

  # Boot configuration
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Networking
  networking.networkmanager.enable = true;

  # User configuration
  users.users.djoolz = {
    isNormalUser = true;
    description = "djoolz";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "docker" ];
  };

  # Home-manager configuration for this machine
  # Uses desktop profile since we need GUI for management
  home-manager.users.djoolz = import ../../flake/homes/profiles/desktop.nix;

  # Machine-specific packages
  environment.systemPackages = with pkgs; [
    # Add homelab-specific tools here
  ];

  system.stateVersion = "23.11";
}
```

#### 5.3 Validation

```bash
# Evaluate machines with new structure
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel

# Check specific values propagated correctly
nix eval .#nixosConfigurations.centauri.config.networking.hostName
# Should output: "centauri"

nix eval .#nixosConfigurations.centauri.config.services.xserver.desktopManager.gnome.enable
# Should output: true

nix eval .#nixosConfigurations.centauri.config.virtualisation.docker.rootless.enable
# Should output: true

nix eval .#nixosConfigurations.mirach.config.virtualisation.libvirtd.enable
# Should output: true
```

### Phase 6: Update Orchestration

**Goal:** Simplify outputs.nix to just coordinate imports

#### 6.1 Update outputs.nix

**Replace `outputs.nix` with:**
```nix
{ self, flake-parts, ... }@inputs:

(flake-parts.lib.mkFlake { inherit inputs; } {

  # Import all flake-parts modules
  imports = [
    # perSystem functionality (development tools, checks, etc.)
    ./parts/systems.nix
    ./parts/devshells.nix
    ./parts/formatter.nix
    ./parts/packages.nix
    ./parts/checks.nix

    # Flake-level outputs (machines, homes, exported modules)
    ./flake/lib.nix
    ./flake/machines/workstations.nix
    ./flake/machines/homelabs.nix
    ./flake/homes/djoolz.nix
    ./flake/modules.nix

    # External flake modules
    inputs.home-manager.flakeModules.home-manager
    inputs.treefmt-nix.flakeModule
  ];
})
```

#### 6.2 Create modules export

**Create `flake/modules.nix`:**
```nix
{ inputs, ... }:
{
  # Export reusable NixOS modules for other flakes
  # Usage: inputs.my-config.nixosModules.gnome
  flake.nixosModules = {
    # Desktop environments
    gnome = ./modules/nixos/desktop/gnome.nix;
    plasma = ./modules/nixos/desktop/plasma.nix;

    # Virtualization
    libvirtd = ./modules/nixos/virtualisation/libvirtd.nix;
    docker = ./modules/nixos/virtualisation/docker.nix;
    docker-rootless = ./modules/nixos/virtualisation/docker-rootless.nix;
    podman = ./modules/nixos/virtualisation/podman.nix;
    quickemu = ./modules/nixos/virtualisation/quickemu.nix;

    # Services
    tailscale = ./modules/nixos/services/tailscale.nix;
    ssh = ./modules/nixos/services/ssh.nix;
    android = ./modules/nixos/services/android.nix;

    # Roles
    workstation = ./modules/nixos/roles/workstation.nix;
    homelab = ./modules/nixos/roles/homelab.nix;
  };

  # Export home-manager modules
  # Usage: inputs.my-config.homeModules.desktop
  flake.homeModules = {
    common = ./flake/homes/profiles/common.nix;
    desktop = ./flake/homes/profiles/desktop.nix;
  };
}
```

#### 6.3 Update flake.nix comments

**Update `flake.nix` with better documentation:**
```nix
{
  description = "NixOS configuration";

  inputs = {
    # Stable nixpkgs (25.11)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Nixpkgs unstable for packages that need newer versions
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Pinned nixpkgs for Tailscale stability
    nixpkgs-tailscale.url =
      "github:nixos/nixpkgs/ce01daebf8489ba97bd1609d185ea276efdeb121";

    # Home-manager for user environment management
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flatpak support
    nix-flatpak.url = "github:gmodena/nix-flatpak/";

    # Future: NixOS configuration editor
    # nixos-conf-editor.url = "github:snowfallorg/nixos-conf-editor";
    # nix-software-center.url = "github:snowfallorg/nix-software-center";

    # Code formatting
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Future: Encrypted key management
    # sops-nix = {
    #   url = "github:Mic92/sops-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Flake-parts for modular flake structure
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Secret management (alternative to sops-nix)
    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System architecture helpers
    systems.url = "github:nix-systems/default";

    # Hardware-specific configurations
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Future: KVM mouse/keyboard sharing
    # lan-mouse.url = "github:feschber/lan-mouse";
  };

  outputs = { self, ... }@args: import ./outputs.nix args;
}
```

#### 6.4 Validation

```bash
# Full validation suite
nix flake check

# Show all outputs
nix flake show

# Verify NixOS configurations
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel

# Verify home-manager configurations
nix eval .#homeConfigurations."djoolz@workstation".activationPackage
nix eval .#homeConfigurations."djoolz@server".activationPackage

# Test dev shell
nix develop --command echo "✓ Dev shell works"

# Test formatter
nix fmt -- --version
```

### Phase 7: Clean Up

**Goal:** Remove old files and update documentation

#### 7.1 Remove old structure

```bash
# Remove old configurations.nix (now replaced by flake/machines/*.nix)
rm nixos/configurations.nix

# Remove old treefmt.nix (moved to parts/formatter.nix)
# Already done in Phase 1

# Remove empty common directory (all modules moved)
rmdir nixos/machines/common/virtualisation
rmdir nixos/machines/common
```

#### 7.2 Update CLAUDE.md

Update the repository overview and architecture sections to reflect new structure.

#### 7.3 Final validation

```bash
# Complete validation
nix flake check
nix flake show

# Test all configurations evaluate
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel
nix eval .#homeConfigurations."djoolz@workstation".activationPackage
nix eval .#homeConfigurations."djoolz@server".activationPackage

# Only when all evals pass - do a dry-build
nixos-rebuild dry-build --flake .#centauri

# When confident - test on actual system
# sudo nixos-rebuild test --flake .#centauri

# When everything works - commit and switch
# sudo nixos-rebuild switch --flake .#centauri
```

## Quick Validation Script

Create `validate.sh` for rapid testing:

```bash
#!/usr/bin/env bash
set -e

echo "=== NixOS Configuration Validation ==="

echo "1. Checking flake structure..."
nix flake check

echo "2. Evaluating centauri..."
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel > /dev/null
echo "  ✓ hostname: $(nix eval --raw .#nixosConfigurations.centauri.config.networking.hostName)"
echo "  ✓ GNOME: $(nix eval --raw .#nixosConfigurations.centauri.config.services.xserver.desktopManager.gnome.enable)"

echo "3. Evaluating mirach..."
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel > /dev/null
echo "  ✓ hostname: $(nix eval --raw .#nixosConfigurations.mirach.config.networking.hostName)"
echo "  ✓ libvirtd: $(nix eval --raw .#nixosConfigurations.mirach.config.virtualisation.libvirtd.enable)"

echo "4. Evaluating home configurations..."
nix eval .#homeConfigurations."djoolz@workstation".activationPackage > /dev/null
echo "  ✓ djoolz@workstation"
nix eval .#homeConfigurations."djoolz@server".activationPackage > /dev/null
echo "  ✓ djoolz@server"

echo "5. Testing dev shell..."
nix develop --command echo "  ✓ Dev shell accessible"

echo ""
echo "=== All Validations Passed ==="
```

## Benefits After Refactoring

1. **Clear organization** - Each concern has its own module
2. **Reusable components** - Modules can be imported by other flakes
3. **Role-based** - Workstation vs homelab clearly separated
4. **Flexible users** - Home-manager configs decoupled from machines
5. **Easy to extend** - Add new machines by referencing roles
6. **Self-documenting** - Structure makes it clear where things belong
7. **Fast iteration** - Use `nix eval` instead of full rebuilds

## Future Enhancements

Once refactoring is complete, consider:

1. **Split user packages** - Separate CLI tools from GUI apps
2. **Environment profiles** - Development, gaming, productivity
3. **Machine templates** - Starter configs for new machines
4. **CI checks** - Automated validation of all configs
5. **Secret management** - Integrate sops-nix or agenix
6. **Remote deployment** - Use deploy-rs or colmena
7. **NixOS tests** - Integration tests for critical services

## Migration Safety

- **All phases are incremental** - Previous config keeps working
- **Fast validation** - Use `nix eval` instead of rebuilds
- **Git checkpoints** - Commit after each phase
- **Easy rollback** - Can revert to any commit
- **No data loss** - Configuration only, doesn't touch user data