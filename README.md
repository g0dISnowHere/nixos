# NixOS Configuration

A system-agnostic, modular NixOS configuration using flake-parts for managing multiple machines.

## Structure

```
├── flake.nix                     # Main flake definition with inputs
├── outputs.nix                   # Flake-parts configuration with system outputs
├── treefmt.nix                   # Code formatting configuration
├── nixos/
│   ├── configuration.nix         # Base NixOS configuration (shared across all machines)
│   ├── configurations.nix        # Machine configuration builder
│   ├── *.nix                     # Modular NixOS configurations (services, networking, etc.)
│   └── users/
│       ├── djoolz.nix            # User-specific home-manager configuration
│       └── modules/               # Modular home-manager configurations
│           ├── packages.nix       # User packages
│           ├── programs.nix       # Program configurations
│           └── shell.nix          # Shell configuration
├── machines/
│   ├── template/                  # Template for new machines
│   │   └── default.nix
│   ├── centauri/                  # Example machine configuration
│   │   ├── default.nix            # Machine-specific configuration
│   │   ├── hardware-configuration.nix
│   │   ├── bootloader.nix
│   │   └── other-hardware.nix
│   ├── powermanagement.nix        # Shared power management module
│   └── autoupgrade.nix            # Shared auto-upgrade module
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

1. **Copy the template**:
   ```bash
   cp -r machines/template machines/your-machine-name
   ```

2. **Generate hardware configuration**:
   ```bash
   sudo nixos-generate-config --show-hardware-config > machines/your-machine-name/hardware-configuration.nix
   ```

3. **Edit machine configuration**:
   Edit `machines/your-machine-name/default.nix` to customize for your machine.

4. **Add to configurations**:
   Edit `nixos/configurations.nix` and add your machine:
   ```nix
   your-machine-name = mkNixosSystem {
     system = "x86_64-linux";  # or "aarch64-linux"
     hostname = "your-machine-name";
     modules = [
       # Add any machine-specific modules here
     ];
   };
   ```

5. **Build and deploy**:
   ```bash
   sudo nixos-rebuild switch --flake .#your-machine-name
   ```

## Adding a New User

1. **Create user configuration**:
   ```bash
   cp nixos/users/djoolz.nix nixos/users/new-user.nix
   ```

2. **Edit user configuration**:
   Update the username and home directory in the new file.

3. **Add to machine configuration**:
   Edit `nixos/configurations.nix` and add the user to home-manager:
   ```nix
   users.new-user = import ./users/new-user.nix;
   ```

## Supported Systems

- `x86_64-linux` - 64-bit Intel/AMD Linux
- `aarch64-linux` - 64-bit ARM Linux (e.g., Raspberry Pi 4)

Additional systems can be added by updating the `systems` list in `outputs.nix`.

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

See `../docs/auto-commit-flake-lock.md` for complete automation documentation.

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

## Customization

### Machine-Specific Configuration

Each machine can have its own:
- Hardware configuration
- Bootloader settings  
- Network configuration
- Services and programs
- Users and permissions

### Shared Modules

Common functionality is shared through:
- `nixos/configuration.nix` - Base system configuration
- `machines/*.nix` - Reusable machine modules
- `nixos/users/modules/*.nix` - Reusable user modules

### Adding New Modules

1. Create the module file in the appropriate directory
2. Import it in the relevant configuration file
3. Document any new options or dependencies

## Troubleshooting

### Common Issues

1. **Import errors**: Check that all file paths in imports are correct
2. **System mismatch**: Ensure the system in configurations.nix matches your hardware
3. **Missing dependencies**: Make sure all required inputs are in flake.nix

### Debugging

View flake structure:
```bash
nix flake show
```

Check configuration:
```bash
nixos-rebuild dry-build --flake .#machine-name
```

## Migration from Old Configuration

This configuration replaces the previous monolithic setup. The key changes:

1. **Modular structure**: Configuration is split into logical modules
2. **Multi-system support**: Can build for different architectures
3. **Machine abstraction**: Easy to add new machines
4. **Flake-parts integration**: Proper use of modern Nix flake patterns

To migrate from the old configuration, machines should be gradually moved to the new structure by creating machine-specific directories and updating the configurations.nix file.
