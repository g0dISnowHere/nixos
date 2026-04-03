#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/update-system.sh [options]

Runs branch-safe scheduled update flows for a NixOS host.

Options:
  --mode bootstrap|updater|consumer
                           Bootstrap creates the deploy clone; updater changes
                           flake.lock; consumer only fast-forwards.
  --host HOST               NixOS host name to switch.
  --repo PATH               Live checkout path.
  --repo-user USER          User account used for git/SSH operations.
  --remote REMOTE           Git remote to use. Default: origin
  --repo-url URL            Git URL used to bootstrap the checkout when absent.
  --branch BRANCH           Git branch allowed for automation. Default: main
  --validation-mode MODE    one of: eval, none. Default: eval
EOF
}

mode="consumer"
host="$(hostname -s)"
repo_root=""
repo_user="${SUDO_USER:-$USER}"
remote="origin"
repo_url="git@github.com:g0dISnowHere/nixos.git"
branch="main"
validation_mode="eval"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      mode="${2:?missing mode}"
      shift 2
      ;;
    --host)
      host="${2:?missing host name}"
      shift 2
      ;;
    --repo)
      repo_root="${2:?missing repo path}"
      shift 2
      ;;
    --repo-user)
      repo_user="${2:?missing repo user}"
      shift 2
      ;;
    --remote)
      remote="${2:?missing remote name}"
      shift 2
      ;;
    --repo-url)
      repo_url="${2:?missing repo url}"
      shift 2
      ;;
    --branch)
      branch="${2:?missing branch name}"
      shift 2
      ;;
    --validation-mode)
      validation_mode="${2:?missing validation mode}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$mode" in
  bootstrap|updater|consumer) ;;
  *)
    printf 'Invalid mode: %s\n' "$mode" >&2
    exit 1
    ;;
esac

case "$validation_mode" in
  eval|none) ;;
  *)
    printf 'Invalid validation mode: %s\n' "$validation_mode" >&2
    exit 1
    ;;
esac

if [[ -z "$repo_root" ]]; then
  if [[ "$(id -u)" -eq 0 ]]; then
    repo_home="$(getent passwd "$repo_user" | cut -d: -f6)"
  else
    repo_home="$HOME"
  fi
  repo_root="${repo_home}/nixos-deploy"
fi

tmp_log="$(mktemp)"
tmp_paths="$(mktemp)"
cleanup() {
  rm -f "$tmp_log" "$tmp_paths"
}
trap cleanup EXIT

reboot_state_dir="/var/lib/auto-update"
reboot_state_file="${reboot_state_dir}/reboot-required"

run_as_repo_user() {
  if [[ "$(id -un)" == "$repo_user" ]]; then
    "$@"
  else
    sudo -H -u "$repo_user" "$@"
  fi
}

git_user() {
  run_as_repo_user git -C "$repo_root" "$@"
}

ensure_repo_checkout() {
  if [[ -d "$repo_root/.git" ]]; then
    return 0
  fi

  if [[ -e "$repo_root" && ! -d "$repo_root" ]]; then
    printf 'Refusing to bootstrap repo: %s exists and is not a directory\n' "$repo_root" >&2
    exit 1
  fi

  if [[ -d "$repo_root" ]]; then
    if [[ -n "$(find "$repo_root" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
      printf 'Refusing to bootstrap repo: %s exists and is not a git checkout\n' "$repo_root" >&2
      exit 1
    fi
  else
    mkdir -p "$(dirname "$repo_root")"
  fi

  printf 'Bootstrapping deploy checkout at %s\n' "$repo_root"
  run_as_repo_user git clone --branch "$branch" --single-branch "$repo_url" "$repo_root"
}

current_branch() {
  git_user symbolic-ref --quiet --short HEAD
}

tracked_tree_dirty() {
  ! git_user diff --quiet --ignore-submodules HEAD --
}

tracked_index_dirty() {
  ! git_user diff --cached --quiet --ignore-submodules --
}

require_branch_safe_checkout() {
  local branch_name
  branch_name="$(current_branch 2>/dev/null || true)"
  if [[ "$branch_name" != "$branch" ]]; then
    printf 'Skipping scheduled update: checkout is on "%s", expected "%s"\n' \
      "${branch_name:-detached HEAD}" "$branch"
    exit 0
  fi

  if tracked_tree_dirty || tracked_index_dirty; then
    printf 'Skipping scheduled update: tracked changes are present on %s\n' "$branch"
    exit 0
  fi
}

validate_host() {
  case "$validation_mode" in
    none)
      printf 'Validation: skipped\n'
      ;;
    eval)
      printf 'Validation: nix eval for host %s\n' "$host"
      nix eval ".#nixosConfigurations.${host}.config.system.build.toplevel" >/dev/null
      ;;
  esac
}

git_fetch() {
  git_user fetch "$remote"
}

git_fast_forward() {
  git_user pull --ff-only "$remote" "$branch"
}

switch_system() {
  local rebuild_cmd
  rebuild_cmd=(nixos-rebuild switch --flake ".#${host}")

  printf 'Switching host %s\n' "$host"
  if [[ "$(id -u)" -eq 0 ]]; then
    if ! "${rebuild_cmd[@]}" 2>&1 | tee "$tmp_log"; then
      printf '\nRebuild failed. Matching error lines:\n' >&2
      grep --color=always -i error "$tmp_log" || true
      exit 1
    fi
  else
    if ! sudo "${rebuild_cmd[@]}" 2>&1 | tee "$tmp_log"; then
      printf '\nRebuild failed. Matching error lines:\n' >&2
      grep --color=always -i error "$tmp_log" || true
      exit 1
    fi
  fi
}

run_updater_flow() {
  local before_rev after_pull_rev after_commit_rev pushed_new_commit
  before_rev="$(git_user rev-parse HEAD)"
  pushed_new_commit=0

  git_fetch
  git_fast_forward
  after_pull_rev="$(git_user rev-parse HEAD)"

  printf 'Updating flake inputs on %s/%s\n' "$remote" "$branch"
  run_as_repo_user nix flake update

  validate_host

  if ! git_user diff --quiet -- flake.lock || ! git_user diff --cached --quiet -- flake.lock; then
    git_user add flake.lock
    git_user commit -m "updates" -- flake.lock
    printf 'Git: committed flake.lock with message "updates"\n'
    git_user push "$remote" "$branch"
    pushed_new_commit=1
  else
    printf 'Git: no flake.lock changes to commit\n'
  fi

  after_commit_rev="$(git_user rev-parse HEAD)"
  if [[ "$before_rev" == "$after_pull_rev" && "$after_pull_rev" == "$after_commit_rev" ]]; then
    printf 'Repo: no new revision to apply\n'
    return 0
  fi

  if [[ "$pushed_new_commit" -eq 1 ]]; then
    printf 'Git: pushed %s to %s/%s\n' \
      "$(git_user rev-parse --short HEAD)" "$remote" "$branch"
  fi

  switch_system
}

run_consumer_flow() {
  local before_rev after_rev
  before_rev="$(git_user rev-parse HEAD)"

  git_fetch
  git_fast_forward
  after_rev="$(git_user rev-parse HEAD)"

  if [[ "$before_rev" == "$after_rev" ]]; then
    printf 'Repo: no new %s/%s revision, skipping rebuild\n' "$remote" "$branch"
    return 0
  fi

  validate_host
  switch_system
}

declare -A current_paths=()
collect_requisites() {
  local root="$1"
  if [[ -e "$root" ]]; then
    nix-store --query --requisites "$root"
  fi
}

post_switch_summary() {
  {
    collect_requisites /run/current-system
    collect_requisites "/nix/var/nix/profiles/per-user/$repo_user/profile"
    collect_requisites "/etc/profiles/per-user/$repo_user"

    if [[ "$(id -u)" -eq 0 ]]; then
      local repo_home
      repo_home="$(getent passwd "$repo_user" | cut -d: -f6)"
      if [[ -n "$repo_home" ]]; then
        collect_requisites "$repo_home/.local/state/nix/profiles/profile"
        collect_requisites "$repo_home/.local/state/nix/profiles/home-manager"
      fi
    else
      collect_requisites "$HOME/.local/state/nix/profiles/profile"
      collect_requisites "$HOME/.local/state/nix/profiles/home-manager"
    fi
  } >> "$tmp_paths"

  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    current_paths["$path"]=1
  done < <(sort -u "$tmp_paths")

  declare -A stale_apps=()
  declare -A stale_pids=()
  declare -A session_components=()
  local session_regex ignore_regex proc_dir pid proc_uid comm exe_path is_stale
  local booted_kernel current_kernel need_reboot

  session_regex='^(dbus-broker|dbus-broker-launch|dbus-daemon|gnome-session-binary|gnome-shell|gpg-agent|kactivitymanagerd|kded[0-9]*|kglobalacceld|kwin(_wayland|_x11)?|mutter|niri|pipewire|plasmashell|polkit-gnome-authentication-agent-1|sway|systemd|wireplumber|xdg-desktop-portal(-gtk|-gnome|-kde|-hyprland|-wlr)?|xwayland)$'
  ignore_regex='^(bash|cat|grep|lsof|sed|sh|sort|tail|tee|update-system\.sh|zsh)$'

  for proc_dir in /proc/[0-9]*; do
    [[ -d "$proc_dir" ]] || continue
    pid="${proc_dir##*/}"

    if [[ "$pid" -eq "$$" || "$pid" -eq "$PPID" ]]; then
      continue
    fi

    proc_uid="$(stat -c '%u' "$proc_dir" 2>/dev/null || true)"
    if [[ "$(id -u)" -eq 0 ]]; then
      local repo_uid
      repo_uid="$(id -u "$repo_user")"
      [[ "$proc_uid" == "$repo_uid" ]] || continue
    else
      [[ "$proc_uid" == "$UID" ]] || continue
    fi

    comm="$(tr -d '\0' < "$proc_dir/comm" 2>/dev/null || true)"
    [[ -n "$comm" ]] || continue

    declare -A seen_proc_paths=()
    exe_path="$(readlink -f "$proc_dir/exe" 2>/dev/null || true)"
    if [[ "$exe_path" == /nix/store/* ]]; then
      seen_proc_paths["$exe_path"]=1
    fi

    while IFS= read -r mapped_path; do
      seen_proc_paths["$mapped_path"]=1
    done < <(grep -o '/nix/store/[^ )]*' "$proc_dir/maps" 2>/dev/null | sort -u || true)

    is_stale=0
    for mapped_path in "${!seen_proc_paths[@]}"; do
      if [[ -z "${current_paths[$mapped_path]+x}" ]]; then
        is_stale=1
        break
      fi
    done

    [[ "$is_stale" -eq 1 ]] || continue

    stale_pids["$comm"]+="${pid} "
    if [[ "$comm" =~ $session_regex ]]; then
      session_components["$comm"]=1
      continue
    fi

    if [[ "$comm" =~ $ignore_regex ]]; then
      continue
    fi

    stale_apps["$comm"]=1
  done

  need_reboot=0
  booted_kernel="$(readlink -f /run/booted-system/kernel 2>/dev/null || true)"
  current_kernel="$(readlink -f /run/current-system/kernel 2>/dev/null || true)"
  if [[ -n "$booted_kernel" && -n "$current_kernel" && "$booted_kernel" != "$current_kernel" ]]; then
    need_reboot=1
  fi

  printf '\nPost-switch summary\n'
  printf 'Host: %s\n' "$host"

  if [[ "$need_reboot" -eq 1 ]]; then
    printf 'Reboot: required (kernel changed)\n'
  else
    printf 'Reboot: not required for the current kernel\n'
  fi

  if [[ "${#session_components[@]}" -gt 0 ]]; then
    printf 'Relog: recommended (stale session components detected: '
    printf '%s ' "${!session_components[@]}"
    printf ')\n'
  else
    printf 'Relog: not currently indicated by session processes\n'
  fi

  if [[ "${#stale_apps[@]}" -gt 0 ]]; then
    printf 'Restart these apps to pick up the new generation:\n'
    while IFS= read -r app; do
      printf '  - %s (pids: %s)\n' "$app" "${stale_pids[$app]}"
    done < <(printf '%s\n' "${!stale_apps[@]}" | sort)
  else
    printf 'Apps to restart: none detected in the %s session\n' "$repo_user"
  fi

  if [[ "${#stale_apps[@]}" -eq 0 && "${#session_components[@]}" -eq 0 && "$need_reboot" -eq 0 ]]; then
    printf 'Action: no post-switch action detected\n'
  elif [[ "$need_reboot" -eq 1 ]]; then
    printf 'Action: reboot\n'
    record_reboot_required
  elif [[ "${#session_components[@]}" -gt 0 || "${#stale_apps[@]}" -gt 6 ]]; then
    printf 'Action: logout/login is the simpler path\n'
    clear_reboot_required
  else
    printf 'Action: restart the apps listed above\n'
    clear_reboot_required
  fi
}

record_reboot_required() {
  local message repo_uid runtime_dir

  mkdir -p "$reboot_state_dir"
  cat > "$reboot_state_file" <<EOF
host=$host
repo_user=$repo_user
timestamp=$(date -Is)
reason=kernel_changed
EOF

  message="Auto-update on ${host} changed the running kernel. Reboot required."
  printf '\n*** REBOOT REQUIRED ***\n%s\n\n' "$message"

  if command -v wall >/dev/null 2>&1; then
    printf '%s\n' "$message" | wall || true
  fi

  if command -v systemd-cat >/dev/null 2>&1; then
    printf '%s\n' "$message" | systemd-cat -t auto-update -p warning || true
  fi

  if command -v notify-send >/dev/null 2>&1; then
    repo_uid="$(id -u "$repo_user" 2>/dev/null || true)"
    runtime_dir="/run/user/${repo_uid}"
    if [[ -n "$repo_uid" && -S "${runtime_dir}/bus" ]]; then
      sudo -H -u "$repo_user" \
        XDG_RUNTIME_DIR="$runtime_dir" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=${runtime_dir}/bus" \
        notify-send -u critical "Reboot required" "$message" || true
    fi
  fi
}

clear_reboot_required() {
  rm -f "$reboot_state_file"
}

ensure_repo_checkout
cd "$repo_root"
require_branch_safe_checkout

case "$mode" in
  bootstrap)
    ensure_repo_checkout
    printf 'Bootstrap: repo ready at %s\n' "$repo_root"
    ;;
  updater)
    ensure_repo_checkout
    cd "$repo_root"
    require_branch_safe_checkout
    run_updater_flow
    ;;
  consumer)
    ensure_repo_checkout
    cd "$repo_root"
    require_branch_safe_checkout
    run_consumer_flow
    ;;
esac

if [[ "$mode" != "bootstrap" ]]; then
  post_switch_summary
fi
