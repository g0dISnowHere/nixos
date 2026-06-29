#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

literal_home_go="\$HOME/go"
literal_home_go_bin="\$HOME/go/bin"
literal_pnpm_home="\$HOME/.local/share/pnpm"
literal_pnpm_global_bin="\$HOME/.local/share/pnpm/bin"
literal_cargo_bin="\$HOME/.cargo/bin"
literal_ssh_identity='~'"/.ssh/id_ed25519"

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
assert_not_contains "$centauri_packages" "gemini-cli-" "system packages leave gemini-cli to pnpm globals"
assert_not_contains "$centauri_packages" "codex-" "system packages leave codex to pnpm globals"

centauri_gopath="$(nix eval --raw .#nixosConfigurations.centauri.config.environment.sessionVariables.GOPATH)"
assert_contains "$centauri_gopath" "$literal_home_go" "developer GOPATH is exported as a session variable"

centauri_gobin="$(nix eval --raw .#nixosConfigurations.centauri.config.environment.sessionVariables.GOBIN)"
assert_contains "$centauri_gobin" "$literal_home_go_bin" "developer GOBIN is exported as a session variable"

centauri_pnpm_home="$(nix eval --raw .#nixosConfigurations.centauri.config.environment.sessionVariables.PNPM_HOME)"
assert_contains "$centauri_pnpm_home" "$literal_pnpm_home" "developer PNPM_HOME is exported as a session variable"

centauri_pnpm_global_dir="$(nix eval --raw '.#nixosConfigurations.centauri.config.environment.sessionVariables.pnpm_config_global_dir')"
assert_contains "$centauri_pnpm_global_dir" "$literal_pnpm_home/global" "system config exports pnpm global package dir"

centauri_pnpm_global_bin_dir="$(nix eval --raw '.#nixosConfigurations.centauri.config.environment.sessionVariables.pnpm_config_global_bin_dir')"
assert_contains "$centauri_pnpm_global_bin_dir" "$literal_pnpm_global_bin" "system config exports pnpm global bin dir"

centauri_pnpm_min_age="$(nix eval --raw '.#nixosConfigurations.centauri.config.environment.sessionVariables.pnpm_config_minimum_release_age')"
assert_contains "$centauri_pnpm_min_age" "20160" "system config exports pnpm release cooldown"

centauri_session_vars="$(nix eval --json .#nixosConfigurations.centauri.config.environment.sessionVariables)"
assert_not_contains "$centauri_session_vars" "NPM_CONFIG_PREFIX" "system config no longer exports npm global prefix"

standalone_session_vars="$(nix eval --json '.#homeConfigurations."djoolz@workstation".config.home.sessionVariables')"
assert_not_contains "$standalone_session_vars" "NPM_CONFIG_PREFIX" "standalone Home Manager no longer exports npm global prefix"

standalone_packages="$(nix eval --json '.#homeConfigurations."djoolz@workstation".config.home.packages')"
assert_not_contains "$standalone_packages" "gemini-cli-" "standalone Home Manager leaves gemini-cli to pnpm globals"
assert_not_contains "$standalone_packages" "codex-" "standalone Home Manager leaves codex to pnpm globals"
assert_contains "$standalone_packages" "opencode-" "standalone Home Manager keeps unstable AI CLI packages"

centauri_extra_init="$(nix eval --raw .#nixosConfigurations.centauri.config.environment.extraInit)"
assert_contains "$centauri_extra_init" "$literal_home_go_bin" "developer PATH wiring includes Go user binaries"
assert_contains "$centauri_extra_init" "$literal_pnpm_global_bin" "developer PATH wiring includes pnpm user binaries"
assert_not_contains "$centauri_extra_init" ".npm-global/bin" "developer PATH wiring no longer includes npm user binaries"
assert_contains "$centauri_extra_init" "$literal_cargo_bin" "developer PATH wiring includes cargo user binaries"

centauri_zsh_init="$(nix eval --raw .#nixosConfigurations.centauri.config.programs.zsh.interactiveShellInit)"
assert_contains "$centauri_zsh_init" "alias npx='pnpm dlx'" "interactive shell aliases npx to pnpm dlx"
assert_contains "$centauri_zsh_init" "npm() {" "interactive shell installs npm compatibility wrapper"
assert_contains "$centauri_zsh_init" 'command pnpm create "$@"' "interactive shell preserves npm init/create scaffolder flow"
assert_contains "$centauri_zsh_init" "unsupported subcommand" "interactive shell warns on unsupported npm subcommands"

standalone_ssh="$(nix eval --json --apply 'x: x.config.programs.ssh.matchBlocks."*".data' '.#homeConfigurations."djoolz@workstation"')"
assert_contains "$standalone_ssh" "$literal_ssh_identity" "standalone Home Manager still keeps SSH matchBlocks"

integrated_matchblocks="$(nix eval --json .#nixosConfigurations.centauri.config.home-manager.users.djoolz.programs.ssh.matchBlocks)"
assert_not_contains "$integrated_matchblocks" "id_ed25519" "integrated Home Manager no longer duplicates SSH matchBlocks"
