#!/usr/bin/env sh
# Setup script for NixOS flake repository
# Run this after cloning to configure development environment

set -e

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOTFILES_LINKER="${REPO_ROOT}/dotfiles/scripts/link.sh"

echo "🔧 Setting up NixOS flake repository..."
echo ""

# Configure git hooks
echo "📌 Configuring git pre-commit hooks..."
git config core.hooksPath .githooks
echo "   ✓ Git configured to use .githooks"
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

if [ -f "${DOTFILES_LINKER}" ]; then
    echo "🔗 Dotfile links..."
    if [ -t 0 ]; then
        printf "   Link repo-managed dotfiles into your home directory now? [y/N] "
        read -r link_dotfiles
    else
        link_dotfiles="n"
    fi

    case "${link_dotfiles}" in
        y|Y|yes|YES)
            bash "${DOTFILES_LINKER}"
            echo "   ✓ Dotfiles linked"
            ;;
        *)
            echo "   Skipped. Run this later with: dotfiles/scripts/link.sh"
            ;;
    esac
    echo ""
fi

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
