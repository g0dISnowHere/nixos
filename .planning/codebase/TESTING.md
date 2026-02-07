# Testing Patterns

**Analysis Date:** 2026-02-04

## Test Framework

**Runner:**
- No formal test framework detected
- NixOS configuration uses declarative validation at build time via `nix flake check`
- Configuration is validated during `nixos-rebuild` operations

**Build Validation:**
- Config: `flake.nix` and `outputs.nix` define flake structure
- Validation: Nix type system validates options during evaluation
- Error detection: Type mismatches and missing required options caught at build time

**Run Commands:**
```bash
# Build and switch to new configuration
sudo nixos-rebuild switch --flake .#

# Test configuration without switching
sudo nixos-rebuild test --flake .#

# Format check
nix flake check

# Manual testing script for bridge networking
bash ./nixos/machines/common/virtualisation/test-bridge-networking.sh
```

## Test File Organization

**Location:**
- Single manual testing script: `nixos/machines/common/virtualisation/test-bridge-networking.sh`
- Not co-located with configuration files
- Located in specialized subdirectory (`virtualisation/`)

**Naming:**
- Pattern: `test-*.sh` for test scripts
- Example: `test-bridge-networking.sh` tests bridge networking configuration

**Structure:**
- Functional test script, not unit tests
- Performs system-level verification via command execution
- Organized in sequential sections with numeric labels

## Test Structure

**Test Script Organization:**
```bash
#!/usr/bin/env bash

# Header comment explaining purpose
# Bridge Networking Test Script

# Sections with numbered output (lines 1-10 in test-bridge-networking.sh)
echo "=== Bridge Networking Test Script ==="

# Conditional checks with visual pass/fail indicators
echo "1. Checking if bridge br0 exists:"
if ip link show br0 &>/dev/null; then
    echo "✓ Bridge br0 exists"
else
    echo "✗ Bridge br0 not found"
fi
```

**Patterns:**
- Setup: Script initialization and header output
- Execution: Sequential system checks using standard Linux utilities (ip, brctl, nmcli, iptables, virsh)
- Verification: Conditional output with pass/fail indicators (✓ and ✗)
- Reporting: Structured section headers with echo statements
- Documentation: Footer section explains manual test procedure (lines 84-88)

**Output Structure:**
- Section headers with numbering: `"1. Checking if bridge br0 exists:"`
- Status indicators: `✓` for success, `✗` for failure
- Command output captured directly in echo statements
- Clear separation between sections

## Mocking

**Framework:** Not applicable - no unit testing framework

**Patterns:**
- No mocking visible in codebase
- Configuration-level testing via disabled modules (comments out integrations that aren't needed)
- Example from `nixos/machines/centauri/configuration.nix`: commented imports allow testing different service combinations:
  - Line 12: `# ./homeassistant.nix` (disabled for testing)
  - Line 16: `# ./ssh.nix` (optional feature disabled)
  - Lines 19-23: various virtualisation backends commented out for selective testing

**What to Mock:**
- Not applicable - NixOS uses declarative approach
- Alternative approach: Comment out or disable modules instead of mocking

**What NOT to Mock:**
- Not applicable - built-in NixOS services and options should not be mocked
- Hardware configuration should reflect actual hardware (auto-generated)
- Core system options validated by NixOS type system

## Fixtures and Factories

**Test Data:**
- No formal fixtures in this repo
- Hardware configuration auto-generated: `hardware-configuration.nix`
- Configuration templates provided in `nixos/machines/template/default.nix` as reference
- Machine-specific configurations stored in machine directories: `centauri/`, `mirach/`, `karakan/`

**Location:**
- Machine configurations: `nixos/machines/[hostname]/`
- User configurations: `nixos/users/`
- Shared modules: `nixos/machines/common/`
- Template for new machines: `nixos/machines/template/default.nix`

## Coverage

**Requirements:** Not enforced - declarative configuration approach

**View Coverage:**
- Not applicable - Nix options are verified at build time
- All enabled options must be valid (type-checked by NixOS module system)

## Test Types

**Unit Tests:**
- Not used - NixOS uses declarative validation
- Configuration syntax validated by Nix evaluator
- Options validated by NixOS module system types

**Integration Tests:**
- Manual testing via scripts (e.g., `test-bridge-networking.sh`)
- Real system testing: `sudo nixos-rebuild test --flake .#` for live config testing
- Integration verification (lines 58-68 of test-bridge-networking.sh): checks if systems interact correctly:
  - Bridge networking with libvirt
  - VM connectivity verification
  - Network namespace checks

**E2E Tests:**
- Manual system testing after rebuild
- Script provides procedure (test-bridge-networking.sh lines 84-88):
  - Create VM using br0 network in virt-manager
  - Verify VM gets IP from DHCP
  - Ping VM from other network devices
  - Verify internet connectivity

## Common Patterns

**Configuration Testing:**
```bash
# Conditional check with output capture
if ip link show br0 &>/dev/null; then
    echo "✓ Bridge br0 exists"
    ip addr show br0
else
    echo "✗ Bridge br0 not found"
fi
```

**Error Handling in Tests:**
```bash
# Test for command availability before using it
if command -v brctl &>/dev/null; then
    brctl show br0
else
    echo "Using ip command instead of brctl:"
    bridge link show master br0
fi
```

**System State Verification:**
```bash
# Check kernel parameters
echo "6. IP Forwarding:"
sysctl net.ipv4.ip_forward

# Check system files
echo "7. Bridge netfilter settings:"
echo "bridge-nf-call-iptables: $(cat /proc/sys/net/bridge/bridge-nf-call-iptables 2>/dev/null || echo 'N/A')"
```

**Attribute Check Pattern:**
```bash
# Verify NetworkManager unmanaged devices
nmcli device status | grep -E "(br0|enp0s31f6)" || echo "Devices not found in NetworkManager"
```

## Validation Approach

**Build-Time Validation:**
- Nix flake check: `nix flake check`
- Syntax validation: Nix parser checks all .nix files
- Type validation: NixOS module system validates all option types
- Referential validation: Cross-references between modules checked

**Runtime Validation:**
- `nixos-rebuild test`: Validates configuration can build and activates without persisting
- Hardware compatibility: Hardware-configuration.nix ensures module availability
- Service dependencies: systemd services validate ordering
- Manual verification: Shell scripts validate specific subsystems

## Linting & Static Analysis

**Tools:**
- `statix`: NixOS linter (included in devShell in `outputs.nix` line 34)
- `deadnix`: Detects unused code (included in devShell)
- `nixpkgs-fmt`: Alternative formatter (included in devShell)
- `treefmt`: Meta-formatter coordinating all formatters (`treefmt.nix`)

**Run Analysis:**
```bash
# Development shell includes analysis tools
nix develop

# Run treefmt to format and check
treefmt --check nixos/

# Run individual tools
statix check nixos/
deadnix nixos/
```

**Configuration Validation:**
- Options checked against NixOS option definitions (provided by nixpkgs)
- Recursive options validated for nested attributes
- Service configuration validated against service module schemas

## Documentation Testing

**Inline Documentation:**
- Comments explain kernel parameters: `"nohz_full=2-7" # NixOS produces many wakeups per second...`
- Wiki links provided for complex configurations: `# https://nixos.wiki/wiki/KDE`
- GitHub repository links documented (e.g., dconf2nix source URL)

**Verification Procedure:**
- Manual testing documented in script footer (test-bridge-networking.sh lines 84-88)
- Configuration comments explain expected behavior
- README available (README.md) for general setup documentation

---

*Testing analysis: 2026-02-04*
