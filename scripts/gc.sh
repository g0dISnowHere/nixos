#!/usr/bin/env bash
# gc.sh - Garbage collection for Nix and related tools
# Removes old generations and unreachable store paths older than 10 days.

set -euo pipefail

KEEP_DAYS=10

resolve_system_tool() {
    local tool="$1"
    local candidate

    candidate="$(command -v "$tool" 2>/dev/null || true)"
    if [[ -n "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
    fi

    candidate="/run/current-system/sw/bin/${tool}"
    if [[ -x "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
    fi

    return 1
}

echo "==> Cleaning devenv..."
if command -v devenv &>/dev/null; then
    devenv gc
else
    echo "    devenv not found, skipping."
fi

echo "==> Pruning pnpm store..."
if pnpm_cmd="$(resolve_system_tool pnpm)"; then
    "$pnpm_cmd" store prune
else
    echo "    pnpm not found, skipping."
fi

echo "==> Pruning uv cache..."
if uv_cmd="$(resolve_system_tool uv)"; then
    "$uv_cmd" cache prune
else
    echo "    uv not found, skipping."
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
