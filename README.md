# NixOS Configuration

A modular NixOS flake using flake-parts, explicit role composition, and
standalone or machine-attached Home Manager profiles.

## Structure

```
├── flake.nix
├── outputs.nix
├── flake/
│   ├── lib.nix                    # mkNixosSystem + helpers
│   ├── machines/
│   │   ├── workstations.nix       # Workstation definitions
│   │   └── homelabs.nix           # Homelab definitions
│   └── homes/
│       ├── djoolz.nix             # Standalone home-manager configs
│       ├── profiles/              # Reusable HM profile layers
│       └── users/                 # User-specific HM wrappers
├── modules/
│   ├── nixos/
│   │   ├── desktop/               # common + DE modules
│   │   ├── roles/                 # workstation, homelab
│   │   ├── services/              # system services
│   │   ├── system/                # base system modules
│   │   └── virtualisation/        # VM/container modules
│   └── home/                      # home-manager modules by concern
├── nixos/
│   └── machines/                  # per-host configs + hardware
├── dotfiles/                      # repo-managed raw config files
└── parts/                         # flake-parts modules
```

## Features

- **System Agnostic**: Supports multiple architectures (x86_64-linux, aarch64-linux)
- **Explicit Modular Design**: Focused modules with no recursive discovery
- **Flake-parts Integration**: Proper use of flake-parts for multi-system builds
- **Reusable Modules**: Shared configurations for roles, desktops, services, and home profiles
- **Home Manager Layering**: Reusable base profiles plus user-specific wrappers
- **Dotfiles-First Workflow**: Home Manager manages deployment while raw config remains in `dotfiles/`
- **Development Environment**: Per-system development shells with formatting and linting tools

## Adding a New Machine

1. **Create host directory** under [nixos/machines](nixos/machines):
   - Add [nixos/machines/your-host/default.nix](nixos/machines/your-host/default.nix)
   - Add [nixos/machines/your-host/hardware-configuration.nix](nixos/machines/your-host/hardware-configuration.nix)

2. **Define the machine** in [flake/machines/workstations.nix](flake/machines/workstations.nix) or [flake/machines/homelabs.nix](flake/machines/homelabs.nix):
   - Set `system`, `hostname`, `role`, and optional `desktop`
   - Add any extra modules in the `modules` list

3. **Build and deploy**:

   ```bash
   sudo nixos-rebuild switch --flake .#your-host
   ```

## Adding a New User

1. Add or extend reusable profile layers under [flake/homes/profiles](flake/homes/profiles).
2. Add a user-specific wrapper under [flake/homes/users](flake/homes/users) if personal identity or user-only settings are needed.
3. Reference the wrapper from the machine’s [nixos/machines/your-host/default.nix](nixos/machines/your-host/default.nix) under `home-manager.users`, or add a standalone config in [flake/homes/djoolz.nix](flake/homes/djoolz.nix).

## Supported Systems

- `x86_64-linux` - 64-bit Intel/AMD Linux
- `aarch64-linux` - 64-bit ARM Linux (e.g., Raspberry Pi 4)

Additional systems can be added by updating the systems list in [outputs.nix](outputs.nix).

## Development

Enter the development environment:

```bash
nix develop
```

This provides tools for:

- `nixpkgs-fmt` - Nix code formatting
- `statix` - Nix static analysis
- `deadnix` - Dead code detection

### Validation Workflow

The repo is designed around fast evaluation first:

```bash
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#nixosConfigurations.mirach.config.system.build.toplevel
nix eval .#homeConfigurations."djoolz@workstation".activationPackage
nix eval .#homeConfigurations."djoolz@server".activationPackage
```

For broader validation:

```bash
nix flake check
sh validate.sh
```

## Building

Build a specific machine configuration:

```bash
nix build .#nixosConfigurations.centauri.config.system.build.toplevel
```

Build for all systems:

```bash
nix flake check
```

## Deployment

Local deployment:

```bash
sudo nixos-rebuild switch --flake .#centauri
```

Remote deployment (if using deployment tools):

```bash
# Example with deploy-rs or similar tools
deploy .#centauri
```

## Adding Services

1. Add a module under [modules/nixos/services](modules/nixos/services) (system services) or [modules/home/services](modules/home/services) (user services).
2. Import it in the relevant role module or host file:
   - Roles: [modules/nixos/roles](modules/nixos/roles)
   - Hosts: [nixos/machines/your-host/default.nix](nixos/machines/your-host/default.nix)

## Adding Modules

1. Create the module in the appropriate folder under [modules](modules).
2. Import it explicitly from the role, host, or desktop module.
3. Keep desktop-specific logic inside [modules/nixos/desktop](modules/nixos/desktop).

## Troubleshooting

### Common Issues

1. **Import errors**: Check that all file paths in imports are correct.
2. **System mismatch**: Ensure the `system` value matches your hardware.
3. **Missing modules**: Confirm imports are explicit (no recursive discovery).

### Debugging

View flake structure:

```bash
nix flake show
```

Check configuration:

```bash
nixos-rebuild dry-build --flake .#machine-name
```

## Migration Notes

This repository uses flake-parts with explicit imports and role modules. Hosts
live under [nixos/machines](nixos/machines), system modules live under
[modules/nixos](modules/nixos), and Home Manager is split across reusable
profiles in [flake/homes/profiles](flake/homes/profiles), user wrappers in
[flake/homes/users](flake/homes/users), and focused HM modules under
[modules/home](modules/home).
