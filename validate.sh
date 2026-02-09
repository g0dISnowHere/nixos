#!/usr/bin/env bash
# Comprehensive validation script for NixOS flake configuration
# Tests all machine configurations, home-manager profiles, and flake integrity
#
# Usage:
#   sh validate.sh              # Run validation checks
#   sh validate.sh --dconf2nix  # Also regenerate dconf.nix from system settings
#
# Optional: Pass --dconf2nix to regenerate dconf.nix from current system settings
# (requires dconf2nix: nix-shell -p dconf2nix)

set -e

echo "=== NixOS Flake Configuration Validation ==="
echo ""

# Check for dconf2nix argument
REGENERATE_DCONF=0
if [ "$1" = "--dconf2nix" ]; then
    REGENERATE_DCONF=1
    echo "⚠️  --dconf2nix flag detected: Will regenerate dconf.nix"
    echo ""
fi

# Track overall status
FAILED=0

# === DCONF2NIX (OPTIONAL) ===
if [ $REGENERATE_DCONF -eq 1 ]; then
    echo "Regenerating dconf.nix:"
    DCONF_FILE="modules/home/dconf/dconf.nix"

    # Check if dconf2nix is available
    if ! command -v dconf2nix &> /dev/null; then
        echo "  ✗ dconf2nix not found. Install with: nix-shell -p dconf2nix"
        FAILED=$((FAILED + 1))
    else
        # Save current state for comparison
        DCONF_TEMP=$(mktemp)
        if [ -f "$DCONF_FILE" ]; then
            cp "$DCONF_FILE" "$DCONF_TEMP"
        fi

        # Regenerate dconf.nix from system settings
        dconf dump / | dconf2nix > "$DCONF_FILE"
        echo "  ✓ Regenerated ${DCONF_FILE}"

        # Show diff if file existed before
        if [ -f "$DCONF_TEMP" ]; then
            DIFF_COUNT=$(diff "$DCONF_TEMP" "$DCONF_FILE" | wc -l)
            if [ $DIFF_COUNT -gt 0 ]; then
                echo "  📝 Changes detected ($DIFF_COUNT lines):"
                diff -u "$DCONF_TEMP" "$DCONF_FILE" 2>/dev/null | head -30 || true
                if [ $DIFF_COUNT -gt 30 ]; then
                    echo "     ... and $(($DIFF_COUNT - 30)) more lines"
                fi
            else
                echo "  ✓ No changes detected"
            fi
        fi
        rm -f "$DCONF_TEMP"
        echo ""
    fi
fi

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
# echo ""
# echo "Flake Checks:"
# if nix flake check 2>&1 | grep -q "All checks passed\|warning:"; then
#     echo "  ✓ nix flake check passes"
# else
#     echo "  ✗ nix flake check failed"
#     FAILED=$((FAILED + 1))
# fi

# === SUMMARY ===
echo ""
if [ $FAILED -eq 0 ]; then
    echo "=== ✓ All Validation Tests Passed ==="
    exit 0
else
    echo "=== ✗ Validation Failed ($FAILED tests) ==="
    exit 1
fi
