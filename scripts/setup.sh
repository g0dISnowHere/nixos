#!/usr/bin/env sh
# Setup script for NixOS flake repository
# Run this after cloning to configure development environment

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "🔧 Setting up NixOS flake repository..."
echo ""

# Configure git hooks
echo "📌 Configuring git pre-commit hooks..."
git config core.hooksPath .githooks
echo "   ✓ Git configured to use .githooks"
echo ""

# Initialise AI skill submodules
echo "📦 Initialising AI skill submodules..."
git submodule update --init \
  third-party/skills/mattpocock-skills \
  third-party/skills/stop-slop \
  third-party/skills/caveman
echo "   ✓ AI skill submodules ready"
echo ""

# Verify nix environment
echo "✅ Verifying Nix environment..."
if command -v nix > /dev/null 2>&1; then
    echo "   ✓ Nix is installed"
else
    echo "   ✗ Nix not found. Please install NixOS or nix-shell"
    exit 1
fi
echo ""

# Test validation script
echo "🧪 Testing validation script..."
if sh "${REPO_ROOT}/scripts/validate-fast.sh" > /dev/null 2>&1; then
    echo "   ✓ Fast validation script works"
else
    echo "   ⚠️  Fast validation script failed (this may be okay if you haven't set up hardware yet)"
fi
echo ""

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Review AGENTS.md for architecture overview"
echo "  2. Make changes to flake configuration"
echo "  3. Git will automatically format and validate before commits"
echo ""
