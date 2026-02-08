# NixOS Configuration

A modular NixOS flake using flake-parts, role modules, and optional desktop selection per machine.

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
│       └── profiles/
│           ├── common.nix
│           └── desktop.nix
├── modules/
│   ├── nixos/
│   │   ├── desktop/               # common + DE modules
│   │   ├── roles/                 # workstation, homelab
│   │   ├── services/              # system services
│   │   ├── system/                # base system modules
│   │   └── virtualisation/        # VM/container modules
│   └── home/                      # home-manager modules
├── nixos/
│   └── machines/                  # per-host configs + hardware
└── parts/                         # flake-parts modules
```

## Features

- **System Agnostic**: Supports multiple architectures (x86_64-linux, aarch64-linux)
- **Modular Design**: Easy to add new machines and users
- **Flake-parts Integration**: Proper use of flake-parts for multi-system builds
- **Reusable Modules**: Shared configurations for common functionality
- **Development Environment**: Per-system development shells with useful tools
- **Automated Workflows**: Auto-commit flake.lock files and code formatting
- **Comprehensive Tooling**: Makefile commands, git aliases, and VS Code integration

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

1. Add a home-manager profile under [modules/home](modules/home) or [flake/homes/profiles](flake/homes/profiles).
2. Reference it from the machine’s [nixos/machines/your-host/default.nix](nixos/machines/your-host/default.nix) under `home-manager.users`.

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

### Automated Workflows

The repository includes comprehensive automation for common tasks:

```bash
# Quick status check
make status

# Format code automatically
make format

# Update flakes with auto-commit
make update

# Rebuild system
make rebuild
```

**Git Integration**:

- Code is automatically formatted on every commit
- flake.lock files are automatically staged
- Pre-push hooks prevent unformatted code from being pushed

**VS Code Integration**: Use Ctrl+Shift+P → "Tasks: Run Task" for GUI access to common operations.

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

1. Add a module under [modules/nixos/services](modules/nixos/services) (system services) or [modules/home](modules/home) (user services).
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

This repository uses flake-parts with explicit imports and role modules. Hosts live under [nixos/machines](nixos/machines), while system modules are under [modules/nixos](modules/nixos) and home-manager modules under [modules/home](modules/home).
