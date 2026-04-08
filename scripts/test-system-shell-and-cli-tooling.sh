#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

fail() {
    printf '  ✗ %s\n' "$1"
    exit 1
}

pass() {
    printf '  ✓ %s\n' "$1"
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if grep -Fq "$needle" <<<"$haystack"; then
        pass "$message"
    else
        fail "$message"
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if grep -Fq "$needle" <<<"$haystack"; then
        fail "$message"
    else
        pass "$message"
    fi
}

echo "System shell and CLI tooling regression checks:"

centauri_ssh="$(nix eval --raw .#nixosConfigurations.centauri.config.programs.ssh.extraConfig)"
assert_contains "$centauri_ssh" "AddKeysToAgent yes" "centauri keeps SSH client defaults in programs.ssh.extraConfig"
assert_contains "$centauri_ssh" "IdentityFile ~/.ssh/id_ed25519" "centauri keeps the default SSH identity"

centauri_packages="$(nix eval --json .#nixosConfigurations.centauri.config.environment.systemPackages)"
assert_contains "$centauri_packages" "vscode-" "desktop systems still include vscode"
assert_contains "$centauri_packages" "direnv-" "system shell tooling still includes direnv"
assert_contains "$centauri_packages" "zellij-" "system shell tooling still includes zellij"
assert_contains "$centauri_packages" "ripgrep-" "system shell tooling still includes ripgrep"
assert_contains "$centauri_packages" "gh-" "system developer tooling still includes GitHub CLI"
assert_contains "$centauri_packages" "devenv-" "system developer tooling still includes devenv"

centauri_gopath="$(nix eval --raw .#nixosConfigurations.centauri.config.environment.sessionVariables.GOPATH)"
assert_contains "$centauri_gopath" '$HOME/go' "developer GOPATH is exported as a session variable"

centauri_gobin="$(nix eval --raw .#nixosConfigurations.centauri.config.environment.sessionVariables.GOBIN)"
assert_contains "$centauri_gobin" '$HOME/go/bin' "developer GOBIN is exported as a session variable"

centauri_extra_init="$(nix eval --raw .#nixosConfigurations.centauri.config.environment.extraInit)"
assert_contains "$centauri_extra_init" '$HOME/go/bin' "developer PATH wiring includes Go user binaries"
assert_contains "$centauri_extra_init" '$HOME/.npm-global/bin' "developer PATH wiring includes npm user binaries"
assert_contains "$centauri_extra_init" '$HOME/.cargo/bin' "developer PATH wiring includes cargo user binaries"

standalone_ssh="$(nix eval --json --apply 'x: x.config.programs.ssh.matchBlocks."*".data' '.#homeConfigurations."djoolz@workstation"')"
assert_contains "$standalone_ssh" "~/.ssh/id_ed25519" "standalone Home Manager still keeps SSH matchBlocks"

integrated_matchblocks="$(nix eval --json .#nixosConfigurations.centauri.config.home-manager.users.djoolz.programs.ssh.matchBlocks)"
assert_not_contains "$integrated_matchblocks" "id_ed25519" "integrated Home Manager no longer duplicates SSH matchBlocks"
