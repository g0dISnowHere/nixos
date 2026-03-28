# Desktop Interchangeability Plan

## Goal

Make desktop environments fully interchangeable via a single parameter change:
```nix
desktop = "gnome";  # → desktop = "plasma";
```

No other file changes required. Each desktop module is entirely self-contained:
DE + display manager + audio + printing + Bluetooth + DE-specific packages + DE-specific Flatpak apps + home-manager settings.

## Current Problems

| # | Problem | Location | Impact |
|---|---------|----------|--------|
| 1 | `desktop` not in `specialArgs` | `flake/lib.nix` | Downstream modules can't branch on active DE |
| 2 | Audio/printing/Bluetooth in role, not desktop | `modules/nixos/roles/workstation.nix` | Headless machines get desktop services; desktop modules are incomplete |
| 3 | GNOME Flatpak apps in shared module | `modules/nixos/services/flatpak.nix` | `org.gnome.Extensions` installed on Plasma |
| 4 | GNOME dconf in machine config | `nixos/machines/centauri/default.nix` | `org/gnome/desktop/interface` hardcoded |
| 5 | `dconf2nix` in shared packages | `modules/home/packages/packages.nix` | GNOME-only tool installed on all DEs |
| 6 | Duplicate Flatpak entries | `modules/nixos/services/flatpak.nix` | `com.github.tchx84.Flatseal` listed twice |
| 7 | Duplicate font packages | `modules/nixos/services/flatpak.nix` | Fonts already in `modules/home/packages/packages.nix` |
| 8 | Duplicate Flatpak list | `modules/nixos/system/services.nix` | Overlaps with `modules/nixos/services/flatpak.nix` |
| 9 | Home-manager desktop profile not DE-aware | `flake/homes/profiles/desktop.nix` | Can't conditionally import GNOME vs Plasma home config |
| 10 | No Plasma home-manager module | `modules/home/` | No KDE-specific home config exists |
| 11 | Optional PipeWire in homelab role | `modules/nixos/roles/homelab.nix` | Audio concern leaks into role |
| 12 | No `plasma-manager` flake input | `flake.nix` | No tooling for Plasma home-manager config |

## Design

### After: Module Responsibility

```
mkNixosSystem { desktop = "gnome"; role = "workstation"; }
         │                              │
         ▼                              ▼
 modules/nixos/desktop/         modules/nixos/roles/
 ├── common.nix                 └── workstation.nix
 │   ├── PipeWire/audio             ├── locale
 │   ├── Printing (CUPS)            ├── shell
 │   ├── Bluetooth                  ├── power management
 │   └── Avahi                      ├── networking
 │                                  └── tailscale
 └── gnome.nix
     ├── imports ./common.nix
     ├── GNOME DE + GDM
     ├── programs.dconf.enable
     ├── GNOME Flatpak apps
     └── GNOME packages (dconf2nix)
```

### After: File Structure

```
modules/
├── nixos/
│   ├── desktop/
│   │   ├── common.nix          # NEW — shared desktop infrastructure
│   │   ├── gnome.nix           # MODIFIED — self-contained, imports common.nix
│   │   └── plasma.nix          # MODIFIED — self-contained, imports common.nix
│   └── roles/
│       ├── workstation.nix     # MODIFIED — no more audio/printing/bluetooth
│       └── homelab.nix         # MODIFIED — no more PipeWire
└── home/
    ├── dconf/
    │   └── dconf.nix           # UNCHANGED — stays as-is, imported conditionally
    └── plasma/
        └── plasma.nix          # NEW — Plasma home-manager config via plasma-manager
```

### Self-Containment Checklist

Each desktop module must provide:

- [x] Display server (X11/Wayland)
- [x] Desktop environment
- [x] Display manager (login screen)
- [x] Audio (PipeWire + rtkit)
- [x] Printing (CUPS)
- [x] Bluetooth
- [x] Network service discovery (Avahi)
- [x] DE-specific Flatpak apps
- [x] DE-specific system packages
- [x] DE-specific dconf/settings enablement

## Implementation

### Step 1: Add `plasma-manager` flake input

**File:** `flake.nix`

Add `plasma-manager` as a flake input:
```nix
plasma-manager = {
  url = "github:nix-community/plasma-manager";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
};
```

**File:** `flake/lib.nix`

Wire `plasma-manager` home-manager module into the home-manager integration so it's available when `desktop = "plasma"`.

**Validate:**
```bash
nix flake check
```

### Step 2: Pass `desktop` into `specialArgs`

**File:** `flake/lib.nix`

Add `inherit desktop;` to:
- `specialArgs` (alongside `inherit inputs hostname;`)
- `home-manager.extraSpecialArgs` block

This makes `desktop` available to all NixOS modules and all home-manager modules.

**Validate:**
```bash
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
```

### Step 3: Create `modules/nixos/desktop/common.nix`

**File:** `modules/nixos/desktop/common.nix` (NEW)

Extract shared desktop infrastructure — config that every graphical DE needs regardless of whether it's GNOME, Plasma, or something else:

```nix
{ config, lib, pkgs, ... }: {
  # Shared Desktop Infrastructure
  # Imported by all desktop environment modules (gnome.nix, plasma.nix, etc.)
  # Provides: audio, printing, Bluetooth, network service discovery, X11 base

  # X11 windowing system base
  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ];
    xkb = { layout = "de"; };
  };

  # Audio (PipeWire)
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

  # Network service discovery (printer auto-detection, etc.)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
```

**Validate:**
```bash
nix-instantiate --parse modules/nixos/desktop/common.nix
```

### Step 4: Rewrite `gnome.nix` — self-contained

**File:** `modules/nixos/desktop/gnome.nix`

- Import `./common.nix` (gets audio, printing, Bluetooth, Avahi, X11)
- Remove duplicated `services.xserver` block (now in common)
- Keep GNOME DE + GDM display manager
- Add `programs.dconf.enable = true` (moved from centauri's `default.nix`)
- Add GNOME-specific Flatpak apps: `org.gnome.Extensions`, `org.gnome.PowerStats`
- Add GNOME-specific system packages: `dconf2nix`

**Validate:**
```bash
nix eval .#nixosConfigurations.centauri.config.services.desktopManager.gnome.enable
nix eval .#nixosConfigurations.centauri.config.services.displayManager.gdm.enable
nix eval .#nixosConfigurations.centauri.config.services.pipewire.enable
nix eval .#nixosConfigurations.centauri.config.hardware.bluetooth.enable
```

### Step 5: Rewrite `plasma.nix` — self-contained

**File:** `modules/nixos/desktop/plasma.nix`

- Import `./common.nix` (gets audio, printing, Bluetooth, Avahi, X11)
- Remove duplicated `services.xserver` block (now in common)
- Keep Plasma 6 DE + SDDM display manager
- Add Plasma-specific system packages if needed

**Validate:**
```bash
nix-instantiate --parse modules/nixos/desktop/plasma.nix
```

### Step 6: Remove desktop concerns from role modules

**File:** `modules/nixos/roles/workstation.nix`

Remove (now in `desktop/common.nix`):
- `security.rtkit.enable`
- `services.pipewire` block
- `services.printing.enable`
- `hardware.bluetooth` block
- `services.avahi` block

Keep:
- `networking.networkmanager.enable`
- imports: `locale.nix`, `shell.nix`, `powermanagement.nix`, `services.nix`, `tailscale.nix`

**File:** `modules/nixos/roles/homelab.nix`

Remove (handled by desktop module when present):
- `security.rtkit.enable = lib.mkDefault true;`
- `services.pipewire` mkDefault block

Keep:
- `networking.networkmanager.enable`
- `networking.firewall.enable`
- `services.openssh` block
- imports: `locale.nix`, `shell.nix`, `services.nix`, `ssh.nix`, `tailscale.nix`

**Validate:**
```bash
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel
```

### Step 7: Clean up shared Flatpak module

**File:** `modules/nixos/services/flatpak.nix`

- Remove `"org.gnome.Extensions"` (now in `gnome.nix`)
- Remove `"org.gnome.PowerStats"` (now in `gnome.nix`)
- Remove duplicate `"com.github.tchx84.Flatseal"`
- Remove `environment.systemPackages` font block (fonts already in `modules/home/packages/packages.nix`)

**Validate:**
```bash
nix eval .#nixosConfigurations.centauri.config.services.flatpak.packages
```

### Step 8: Consolidate duplicate Flatpak list from `services.nix`

**File:** `modules/nixos/system/services.nix`

The Flatpak config in this file overlaps with `modules/nixos/services/flatpak.nix`. Merge any unique entries into `flatpak.nix` and remove the Flatpak block from `services.nix`.

**Validate:**
```bash
nix eval .#nixosConfigurations.centauri.config.services.flatpak.packages
```

### Step 9: Move `dconf2nix` out of shared packages

**File:** `modules/home/packages/packages.nix`

Remove `dconf2nix` from the `## Nix Tools` section. It's now installed as a system package by `gnome.nix`.

**Validate:**
```bash
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
```

### Step 10: Clean up centauri machine config

**File:** `nixos/machines/centauri/default.nix`

Remove the `programs.dconf` block with `org/gnome/desktop/interface` — now handled by `gnome.nix`.

**Validate:**
```bash
nix eval .#nixosConfigurations.centauri.config.programs.dconf.enable
```

### Step 11: Make home-manager desktop profile DE-aware

**File:** `flake/homes/profiles/desktop.nix`

Use the new `desktop` arg to conditionally import DE-specific home-manager modules:

```nix
{ config, pkgs, pkgs-unstable, desktop ? null, ... }: {
  # Desktop profile
  # Extends common profile with GUI applications
  # DE-specific settings imported conditionally based on `desktop` arg

  imports = [
    ./common.nix
  ]
  # GNOME: dconf settings (currently disabled — uncomment to enable)
  # ++ (if desktop == "gnome" then [ ../../../modules/home/dconf/dconf.nix ] else [])

  # Plasma: plasma-manager settings
  ++ (if desktop == "plasma" then [ ../../../modules/home/plasma/plasma.nix ] else []);

  fonts.fontconfig.enable = true;
  services.syncthing.enable = true;
}
```

**Validate:**
```bash
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
```

### Step 12: Create Plasma home-manager module

**File:** `modules/home/plasma/plasma.nix` (NEW)

Skeleton Plasma-specific home-manager config using `plasma-manager`:

```nix
{ config, lib, pkgs, ... }: {
  # Plasma Desktop — Home-Manager Settings
  # Parallel to modules/home/dconf/dconf.nix for GNOME
  # Uses plasma-manager for declarative KDE configuration
  # Reference: https://github.com/nix-community/plasma-manager

  programs.plasma = {
    enable = true;

    workspace = {
      # theme = "breeze-dark";
      # iconTheme = "breeze-dark";
    };

    # panels = [ ... ];
    # shortcuts = { ... };
    # configFile = { ... };
  };
}
```

**Validate:**
```bash
nix-instantiate --parse modules/home/plasma/plasma.nix
```

## Validation Checklist

After all steps, run:

```bash
# Flake structure
nix flake check
nix flake show

# Both machines evaluate
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel

# Home configurations
nix eval .#homeConfigurations."djoolz@workstation".activationPackage
nix eval .#homeConfigurations."djoolz@server".activationPackage

# Desktop services come from desktop module, not role
nix eval .#nixosConfigurations.centauri.config.services.pipewire.enable        # true
nix eval .#nixosConfigurations.centauri.config.hardware.bluetooth.enable       # true
nix eval .#nixosConfigurations.centauri.config.services.printing.enable        # true
nix eval .#nixosConfigurations.centauri.config.services.desktopManager.gnome.enable  # true

# GNOME-specific Flatpak apps present
nix eval .#nixosConfigurations.centauri.config.services.flatpak.packages

# Switching test: temporarily change centauri to desktop = "plasma" and re-eval
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
```

## Switching Test

To verify interchangeability works end-to-end:

1. Change `desktop = "gnome"` → `desktop = "plasma"` in `flake/machines/workstations.nix`
2. Run: `nix eval .#nixosConfigurations.centauri.config.system.build.toplevel`
3. Verify: `nix eval .#nixosConfigurations.centauri.config.services.desktopManager.plasma6.enable` → `true`
4. Verify: `nix eval .#nixosConfigurations.centauri.config.services.desktopManager.gnome.enable` → errors or `false`
5. Verify: `nix eval .#nixosConfigurations.centauri.config.services.pipewire.enable` → `true` (still works)
6. Revert the change

## CLAUDE.md Updates Required

After implementation, update `CLAUDE.md`:

- Directory structure: add `common.nix` and `modules/home/plasma/`
- Roles section: remove mention of audio/printing/Bluetooth from workstation role description
- "Adding a New Module" desktop example: show importing `./common.nix`
- "Switching Desktop Environments" section: already accurate, no changes needed

## Adding a New Desktop Environment

After this plan is complete, adding a third DE (e.g., `niri`, `sway`, `hyprland`) requires:

1. Create `modules/nixos/desktop/my-de.nix`:
   ```nix
   { config, lib, pkgs, ... }: {
     imports = [ ./common.nix ];
     # DE-specific config here
   }
   ```
2. Optionally create `modules/home/my-de/my-de.nix` for home-manager settings
3. Add conditional import in `flake/homes/profiles/desktop.nix`
4. Use it: `desktop = "my-de";`

No other files need to change.
