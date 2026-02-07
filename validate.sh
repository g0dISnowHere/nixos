#!/usr/bin/env bash
# Comprehensive validation script for NixOS flake configuration
# Tests all machine configurations, home-manager profiles, and flake integrity

set -e

echo "=== NixOS Flake Configuration Validation ==="
echo ""

echo "Machines:"
echo "  centauri hostname: $(nix eval .#nixosConfigurations.centauri.config.networking.hostName 2>/dev/null | tr -d '"')"
echo "  mirach hostname: $(nix eval .#nixosConfigurations.mirach.config.networking.hostName 2>/dev/null | tr -d '"')"
echo ""

echo "Centauri (Workstation):"
echo "  Desktop (GNOME):"
echo "    - enable: $(nix eval .#nixosConfigurations.centauri.config.services.desktopManager.gnome.enable 2>/dev/null)"
echo "  Virtualization (Docker):"
echo "    - enable: $(nix eval .#nixosConfigurations.centauri.config.virtualisation.docker.enable 2>/dev/null)"
echo "  Home-manager:"
if nix eval ".#homeConfigurations.\"djoolz@workstation\".activationPackage" > /dev/null 2>&1; then
    echo "    - djoolz@workstation: ✓"
else
    echo "    - djoolz@workstation: ✗"
fi
echo ""

echo "Mirach (Homelab):"
echo "  Desktop (GNOME):"
echo "    - enable: $(nix eval .#nixosConfigurations.mirach.config.services.desktopManager.gnome.enable 2>/dev/null)"
echo "  Virtualization:"
echo "    - libvirtd: $(nix eval .#nixosConfigurations.mirach.config.virtualisation.libvirtd.enable 2>/dev/null)"
echo "    - docker: $(nix eval .#nixosConfigurations.mirach.config.virtualisation.docker.enable 2>/dev/null)"
echo "  Home-manager:"
if nix eval ".#homeConfigurations.\"djoolz@server\".activationPackage" > /dev/null 2>&1; then
    echo "    - djoolz@server: ✓"
else
    echo "    - djoolz@server: ✗"
fi
echo ""

echo "Flake Integrity:"
if nix flake check > /dev/null 2>&1; then
    echo "  ✓ All checks passed"
else
    echo "  ✗ Some checks failed"
    exit 1
fi

echo ""
echo "=== Validation Complete ==="
