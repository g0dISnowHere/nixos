#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/sync-rustpackages.sh [--dry-run] [--update]

Sync repo-managed Rust CLI packages from rustpackages/ into the current
user's XDG data directory.

Options:
  --dry-run  Show planned packages and paths without changing state.
  --update   Resolve latest crate versions and rewrite packages.txt.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
source_dir="${repo_root}/rustpackages"
manifest="${source_dir}/packages.txt"
xdg_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
runtime_dir="${xdg_data_home}/mine/rustpackages"
lock_root="${XDG_RUNTIME_DIR:-/tmp}"
lock_file="${lock_root}/mine-rustpackages-$(id -u).lock"
dry_run=0
update_packages=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --update)
      update_packages=1
      shift
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

cargo_cmd="$(command -v cargo || true)"
if [[ -z "$cargo_cmd" && -x /run/current-system/sw/bin/cargo ]]; then
  cargo_cmd=/run/current-system/sw/bin/cargo
fi
if [[ -z "$cargo_cmd" ]]; then
  printf 'cargo is not available in PATH\n' >&2
  exit 1
fi

if [[ ! -r "$manifest" ]]; then
  printf 'Rust packages source file missing or unreadable: %s\n' "$manifest" >&2
  exit 1
fi

packages=()
versions=()
while read -r package version extra; do
  [[ -z "${package:-}" || "${package:0:1}" == "#" ]] && continue
  if [[ -z "${version:-}" || -n "${extra:-}" ]]; then

    printf 'Invalid Rust package entry: %s\n' "$package ${version:-} ${extra:-}" >&2
    exit 1
  fi
  packages+=("$package")
  versions+=("$version")
done < "$manifest"
resolve_latest_versions() {
  local index package latest

  for index in "${!packages[@]}"; do
    package="${packages[$index]}"
    latest="$("$cargo_cmd" info -q "$package" | sed -n 's/^version: //p' | sed -n '1p')"
    if [[ -z "$latest" ]]; then
      printf 'could not resolve latest version for crate: %s\n' "$package" >&2
      exit 1
    fi
    versions[index]="$latest"
  done
}

write_updated_manifest() {
  local temp_manifest line package index

  temp_manifest="$(mktemp "${manifest}.tmp.XXXXXX")"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" || "${line:0:1}" == "#" ]]; then
      printf '%s\n' "$line" >> "$temp_manifest"
      continue
    fi

    read -r package _ <<< "$line"
    for index in "${!packages[@]}"; do
      if [[ "$package" == "${packages[$index]}" ]]; then
        printf '%s %s\n' "$package" "${versions[$index]}" >> "$temp_manifest"
        break
      fi
    done
  done < "$manifest"
  install -m 0644 "$temp_manifest" "$manifest"
  rm -f "$temp_manifest"
}

is_installed() {
  local expected="$1 v$2:"
  while IFS= read -r line; do
    [[ "$line" == "$expected" ]] && return 0
  done < <("$cargo_cmd" install --list --root "$runtime_dir")
  return 1
}

sync_locked_packages() {
  if [[ "$dry_run" -eq 1 ]]; then
    printf 'Rust packages source: %s\n' "$source_dir"
    printf 'Rust packages runtime: %s\n' "$runtime_dir"
    if [[ "$update_packages" -eq 1 ]]; then
      printf 'Would resolve latest crate versions before installing.\n'
    fi
    printf 'Packages:\n'
    for index in "${!packages[@]}"; do
      printf ' - %s %s\n' "${packages[$index]}" "${versions[$index]}"
    done
    return
  fi

  if [[ "$update_packages" -eq 1 ]]; then
    resolve_latest_versions
  fi

  mkdir -p "$runtime_dir"
  for index in "${!packages[@]}"; do
    package="${packages[$index]}"
    version="${versions[$index]}"
    if is_installed "$package" "$version"; then
      printf '%s %s already installed\n' "$package" "$version"
      continue
    fi
    printf 'Installing %s %s in %s\n' "$package" "$version" "$runtime_dir"
    "$cargo_cmd" install \
      --locked \
      --root "$runtime_dir" \
      --version "$version" \
      "$package"
  done
  if [[ "$update_packages" -eq 1 ]]; then
    write_updated_manifest
    printf 'Rust packages: packages.txt updated\n'
  fi
  printf 'Rust packages: sync complete\n'
}

mkdir -p "$(dirname "$lock_file")"
exec 9>"$lock_file"
if ! flock -n 9; then
  printf 'another Rust packages sync is already running\n' >&2
  exit 1
fi

sync_locked_packages
