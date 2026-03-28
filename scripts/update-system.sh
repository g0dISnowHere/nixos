#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/update-system.sh [--host HOST]

Runs nixos-rebuild switch for the selected host, checks whether a reboot is
needed, reports user applications still running old Nix store paths, and
commits flake.lock with message "updates" when it changed.
EOF
}

host="$(hostname -s)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      host="${2:?missing host name}"
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

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmp_log="$(mktemp)"
tmp_paths="$(mktemp)"
cleanup() {
  rm -f "$tmp_log" "$tmp_paths"
}
trap cleanup EXIT

printf 'Switching host %s\n' "$host"
if ! sudo nixos-rebuild switch --flake ".#${host}" 2>&1 | tee "$tmp_log"; then
  printf '\nRebuild failed. Matching error lines:\n' >&2
  grep --color=always -i error "$tmp_log" || true
  exit 1
fi

declare -A current_paths=()
collect_requisites() {
  local root="$1"
  if [[ -e "$root" ]]; then
    nix-store --query --requisites "$root"
  fi
}

collect_requisites /run/current-system >> "$tmp_paths"
collect_requisites "/nix/var/nix/profiles/per-user/$USER/profile" >> "$tmp_paths"
collect_requisites "/etc/profiles/per-user/$USER" >> "$tmp_paths"
collect_requisites "$HOME/.local/state/nix/profiles/profile" >> "$tmp_paths"
collect_requisites "$HOME/.local/state/nix/profiles/home-manager" >> "$tmp_paths"

while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  current_paths["$path"]=1
done < <(sort -u "$tmp_paths")

declare -A stale_apps=()
declare -A stale_pids=()
declare -A session_components=()

session_regex='^(dbus-broker|dbus-broker-launch|dbus-daemon|gnome-session-binary|gnome-shell|gpg-agent|kactivitymanagerd|kded[0-9]*|kglobalacceld|kwin(_wayland|_x11)?|mutter|niri|pipewire|plasmashell|polkit-gnome-authentication-agent-1|sway|systemd|wireplumber|xdg-desktop-portal(-gtk|-gnome|-kde|-hyprland|-wlr)?|xwayland)$'
ignore_regex='^(bash|cat|grep|lsof|sed|sh|sort|tail|tee|update-system\.sh|zsh)$'

for proc_dir in /proc/[0-9]*; do
  [[ -d "$proc_dir" ]] || continue
  pid="${proc_dir##*/}"

  if [[ "$pid" -eq "$$" || "$pid" -eq "$PPID" ]]; then
    continue
  fi

  proc_uid="$(stat -c '%u' "$proc_dir" 2>/dev/null || true)"
  [[ "$proc_uid" == "$UID" ]] || continue

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
  printf 'Apps to restart: none detected in your user session\n'
fi

if [[ "${#stale_apps[@]}" -eq 0 && "${#session_components[@]}" -eq 0 && "$need_reboot" -eq 0 ]]; then
  printf 'Action: no post-switch action detected\n'
elif [[ "$need_reboot" -eq 1 ]]; then
  printf 'Action: reboot\n'
elif [[ "${#session_components[@]}" -gt 0 || "${#stale_apps[@]}" -gt 6 ]]; then
  printf 'Action: logout/login is the simpler path\n'
else
  printf 'Action: restart the apps listed above\n'
fi

if ! git diff --quiet -- flake.lock || ! git diff --cached --quiet -- flake.lock; then
  git add flake.lock
  git commit -m "updates" -- flake.lock
  printf 'Git: committed flake.lock with message "updates"\n'
else
  printf 'Git: no flake.lock changes to commit\n'
fi
