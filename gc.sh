#!/usr/bin/env bash
# gc.sh - Garbage collection for Nix and related tools
# Removes old generations and unreachable store paths older than 10 days.

set -euo pipefail

KEEP_DAYS=10

echo "==> Cleaning devenv..."
if command -v devenv &>/dev/null; then
    devenv gc
else
    echo "    devenv not found, skipping."
fi

echo "==> Cleaning unused Flatpak runtimes..."
if command -v flatpak &>/dev/null; then
    flatpak uninstall --unused --noninteractive
else
    echo "    flatpak not found, skipping."
fi

echo "==> Cleaning Docker (rootless)..."
if command -v docker &>/dev/null; then
    docker system prune --force
else
    echo "    docker not found, skipping."
fi

echo "==> User-level nix garbage collection (older than ${KEEP_DAYS} days)..."
nix-collect-garbage --delete-older-than "${KEEP_DAYS}d"

echo "==> System-level nix garbage collection (older than ${KEEP_DAYS} days)..."
sudo nix-collect-garbage --delete-older-than "${KEEP_DAYS}d"

echo "==> Done."
