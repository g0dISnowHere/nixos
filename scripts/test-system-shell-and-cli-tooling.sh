#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

literal_home_go_bin="\$HOME/go/bin"
literal_local_bin="\$HOME/.local/bin"
literal_pnpm_global_bin="\$HOME/.local/share/pnpm/bin"
literal_cargo_bin="\$HOME/.cargo/bin"
literal_ssh_identity='~'"/.ssh/id_ed25519"

fail() {
  printf ' ✗ %s\n' "$1"
  exit 1
}

pass() {
  printf ' ✓ %s\n' "$1"
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

echo "System shell CLI tooling regression checks:"

centauri_ssh="$(nix eval --raw .#nixosConfigurations.centauri.config.programs.ssh.extraConfig)"
assert_contains "$centauri_ssh" "AddKeysToAgent yes" "centauri keeps SSH client defaults in programs.ssh.extraConfig"
assert_contains "$centauri_ssh" "IdentityFile ~/.ssh/id_ed25519" "centauri keeps default SSH identity"

centauri_packages="$(nix eval --json .#nixosConfigurations.centauri.config.environment.systemPackages)"
assert_contains "$centauri_packages" "vscode-" "desktop systems still include vscode"
assert_contains "$centauri_packages" "direnv-" "system shell tooling still includes direnv"
assert_contains "$centauri_packages" "pnpm-" "system shell tooling keeps pnpm as package manager"
assert_contains "$centauri_packages" "nodejs-" "system shell tooling keeps Node.js"
assert_contains "$centauri_packages" "gh-" "system shell tooling includes GitHub CLI"
assert_not_contains "$centauri_packages" "gemini-cli-" "system packages leave gemini-cli to pnpm-globals"
assert_not_contains "$centauri_packages" "codex-" "system packages leave codex to pnpm-globals"
assert_not_contains "$centauri_packages" "bun-" "system packages leave bun to pnpm-globals"
assert_not_contains "$centauri_packages" "basic-memory-" "system packages leave basic-memory to uv-tools"
assert_not_contains "$centauri_packages" "graphifyy-" "system packages leave graphifyy to uv-tools"
assert_not_contains "$centauri_packages" "headroom-ai-" "system packages leave headroom-ai to uv-tools"
assert_not_contains "$centauri_packages" "specify-cli-" "system packages leave specify-cli to uv-tools"

centauri_gopath="$(nix eval --raw .#nixosConfigurations.centauri.config.environment.sessionVariables.GOPATH)"
assert_contains "$centauri_gopath" "\$HOME/go" "system config exports GOPATH"

centauri_gobin="$(nix eval --raw .#nixosConfigurations.centauri.config.environment.sessionVariables.GOBIN)"
assert_contains "$centauri_gobin" "\$HOME/go/bin" "system config exports GOBIN"

centauri_session_vars="$(nix eval --json .#nixosConfigurations.centauri.config.environment.sessionVariables)"
assert_not_contains "$centauri_session_vars" "NPM_CONFIG_PREFIX" "system config no longer exports npm global prefix"
assert_not_contains "$centauri_session_vars" "PNPM_HOME" "system config no longer exports PNPM_HOME"
assert_not_contains "$centauri_session_vars" "pnpm_config_global_dir" "system config no longer exports pnpm global dir"
assert_not_contains "$centauri_session_vars" "pnpm_config_global_bin_dir" "system config no longer exports pnpm global bin dir"
assert_not_contains "$centauri_session_vars" "pnpm_config_minimum_release_age" "system config leaves pnpm globals policy to pnpm-globals/.npmrc"

standalone_session_vars="$(nix eval --json '.#homeConfigurations."djoolz@workstation".config.home.sessionVariables')"
assert_not_contains "$standalone_session_vars" "NPM_CONFIG_PREFIX" "standalone Home Manager no longer exports npm global prefix"
assert_not_contains "$standalone_session_vars" "PNPM_HOME" "standalone Home Manager does not export PNPM_HOME"

standalone_packages="$(nix eval --json '.#homeConfigurations."djoolz@workstation".config.home.packages')"
assert_not_contains "$standalone_packages" "gemini-cli-" "standalone Home Manager leaves gemini-cli to pnpm-globals"
assert_not_contains "$standalone_packages" "codex-" "standalone Home Manager leaves codex to pnpm-globals"
assert_not_contains "$standalone_packages" "bun-" "standalone Home Manager leaves bun to pnpm-globals"
assert_not_contains "$standalone_packages" "basic-memory-" "standalone Home Manager leaves basic-memory to uv-tools"
assert_not_contains "$standalone_packages" "graphifyy-" "standalone Home Manager leaves graphifyy to uv-tools"
assert_not_contains "$standalone_packages" "headroom-ai-" "standalone Home Manager leaves headroom-ai to uv-tools"
assert_not_contains "$standalone_packages" "specify-cli-" "standalone Home Manager leaves specify-cli to uv-tools"
assert_contains "$standalone_packages" "opencode-" "standalone Home Manager keeps unstable AI CLI packages"

centauri_extra_init="$(nix eval --raw .#nixosConfigurations.centauri.config.environment.extraInit)"
assert_contains "$centauri_extra_init" "$literal_home_go_bin" "developer PATH wiring includes Go user binaries"
assert_contains "$centauri_extra_init" "$literal_local_bin" "developer PATH wiring includes local user binaries"
assert_not_contains "$centauri_extra_init" "$literal_pnpm_global_bin" "developer PATH wiring no longer includes pnpm global bin"
assert_not_contains "$centauri_extra_init" ".npm-global/bin" "developer PATH wiring no longer includes npm user binaries"
assert_contains "$centauri_extra_init" "$literal_cargo_bin" "developer PATH wiring includes cargo user binaries"

centauri_zsh_init="$(nix eval --raw .#nixosConfigurations.centauri.config.programs.zsh.interactiveShellInit)"
assert_contains "$centauri_zsh_init" "alias npx='pnpm dlx'" "interactive shell aliases npx to pnpm dlx"
assert_contains "$centauri_zsh_init" "npm() {" "interactive shell installs npm compatibility wrapper"
assert_contains "$centauri_zsh_init" 'command pnpm create "$@"' "interactive shell preserves npm init/create scaffolder flow"
assert_contains "$centauri_zsh_init" "unsupported subcommand" "interactive shell warns on unsupported npm subcommands"

standalone_ssh="$(nix eval --json --apply 'x: x.config.programs.ssh.settings."*".data' '.#homeConfigurations."djoolz@workstation"')"
assert_contains "$standalone_ssh" "$literal_ssh_identity" "standalone Home Manager still keeps SSH settings identity"

integrated_ssh_settings="$(nix eval --json .#nixosConfigurations.centauri.config.home-manager.users.djoolz.programs.ssh.settings)"
assert_not_contains "$integrated_ssh_settings" "id_ed25519" "integrated Home Manager no longer sets user SSH host settings"
