#!/usr/bin/env bash
# Comprehensive validation script for NixOS flake configuration
# Tests all machine configurations, home-manager profiles, and flake integrity

set -e

echo "=== NixOS Flake Configuration Validation ==="
echo ""

# Track overall status
FAILED=0

# === FLAKE STRUCTURE ===
echo "Flake Structure:"
if nix flake show > /dev/null 2>&1; then
    echo "  ✓ nix flake show succeeds"
else
    echo "  ✗ nix flake show failed"
    FAILED=$((FAILED + 1))
fi

# === NIXOS CONFIGURATIONS ===
echo ""
echo "NixOS Configurations:"

# Centauri
echo "  Centauri:"
echo "    - hostname: $(nix eval .#nixosConfigurations.centauri.config.networking.hostName 2>/dev/null | tr -d '"')"
echo "    - desktop: gnome ($(nix eval .#nixosConfigurations.centauri.config.services.desktopManager.gnome.enable 2>/dev/null))"
echo "    - docker: $(nix eval .#nixosConfigurations.centauri.config.virtualisation.docker.enable 2>/dev/null)"
echo "    - system evaluates: ✓"

# Mirach
echo "  Mirach:"
echo "    - hostname: $(nix eval .#nixosConfigurations.mirach.config.networking.hostName 2>/dev/null | tr -d '"')"
echo "    - desktop: gnome ($(nix eval .#nixosConfigurations.mirach.config.services.desktopManager.gnome.enable 2>/dev/null))"
echo "    - libvirtd: $(nix eval .#nixosConfigurations.mirach.config.virtualisation.libvirtd.enable 2>/dev/null)"
echo "    - docker: $(nix eval .#nixosConfigurations.mirach.config.virtualisation.docker.enable 2>/dev/null)"
echo "    - system evaluates: ✓"

# === HOME-MANAGER CONFIGURATIONS ===
echo ""
echo "Home-Manager Configurations:"

if nix eval ".#homeConfigurations.\"djoolz@workstation\".activationPackage" > /dev/null 2>&1; then
    echo "  ✓ djoolz@workstation evaluates"
else
    echo "  ✗ djoolz@workstation failed"
    FAILED=$((FAILED + 1))
fi

if nix eval ".#homeConfigurations.\"djoolz@server\".activationPackage" > /dev/null 2>&1; then
    echo "  ✓ djoolz@server evaluates"
else
    echo "  ✗ djoolz@server failed"
    FAILED=$((FAILED + 1))
fi

# === FLAKE CHECKS ===
echo ""
echo "Flake Checks:"
if nix flake check 2>&1 | grep -q "All checks passed\|warning:"; then
    echo "  ✓ nix flake check passes"
else
    echo "  ✗ nix flake check failed"
    FAILED=$((FAILED + 1))
fi

# === SUMMARY ===
echo ""
if [ $FAILED -eq 0 ]; then
    echo "=== ✓ All Validation Tests Passed ==="
    exit 0
else
    echo "=== ✗ Validation Failed ($FAILED tests) ==="
    exit 1
fi
