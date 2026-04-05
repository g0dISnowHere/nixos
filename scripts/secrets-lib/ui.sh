#!/usr/bin/env bash

set -euo pipefail

secrets_ui_section() {
  local title="$1"
  printf '%s\n' "${title}"
  printf '%s\n' "$(printf '%*s' "${#title}" '' | tr ' ' '=')"
}

secrets_ui_note() {
  printf '%s\n' "$1"
}

secrets_ui_error() {
  printf '%s\n' "$1" >&2
}

secrets_ui_kv() {
  local key="$1"
  local value="$2"
  printf '%-24s %s\n' "${key}:" "${value}"
}

secrets_ui_confirm() {
  local prompt="$1"
  local reply=""

  printf '%s [y/N]: ' "${prompt}"
  read -r reply
  case "${reply}" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

secrets_ui_choose() {
  local prompt="$1"
  shift
  local options=("$@")
  local idx=1
  local reply=""

  printf '%s\n' "${prompt}" >&2
  for option in "${options[@]}"; do
    printf '  %d. %s\n' "${idx}" "${option}" >&2
    idx=$((idx + 1))
  done

  while true; do
    printf 'Choose 1-%d: ' "${#options[@]}" >&2
    read -r reply
    if [[ "${reply}" =~ ^[0-9]+$ ]] && (( reply >= 1 && reply <= ${#options[@]} )); then
      printf '%s\n' "${options[reply - 1]}"
      return 0
    fi
    printf 'Invalid choice.\n' >&2
  done
}

secrets_ui_choose_many() {
  local prompt="$1"
  shift
  local options=("$@")
  local idx=1
  local reply=""
  local selection=""
  local seen=""
  local picked=()
  local value=""

  printf '%s\n' "${prompt}" >&2
  for option in "${options[@]}"; do
    printf '  %d. %s\n' "${idx}" "${option}" >&2
    idx=$((idx + 1))
  done
  printf 'Choose comma-separated numbers, or press Enter for none.\n' >&2

  while true; do
    printf 'Choose 1-%d: ' "${#options[@]}" >&2
    read -r reply
    if [[ -z "${reply}" ]]; then
      return 0
    fi

    picked=()
    seen=","
    local valid=1
    IFS=',' read -r -A selections <<< "${reply}"
    for selection in "${selections[@]}"; do
      selection="${selection//[[:space:]]/}"
      if [[ ! "${selection}" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#options[@]} )); then
        valid=0
        break
      fi
      if [[ "${seen}" == *",${selection},"* ]]; then
        continue
      fi
      seen="${seen}${selection},"
      value="${options[selection - 1]}"
      picked+=("${value}")
    done

    if [[ "${valid}" -eq 1 ]]; then
      printf '%s\n' "${picked[@]}"
      return 0
    fi

    printf 'Invalid choice.\n' >&2
  done
}

secrets_ui_prompt() {
  local prompt="$1"
  local default_value="${2:-}"
  local reply=""

  if [[ -n "${default_value}" ]]; then
    printf '%s [%s]: ' "${prompt}" "${default_value}" >&2
  else
    printf '%s: ' "${prompt}" >&2
  fi

  read -r reply
  if [[ -z "${reply}" && -n "${default_value}" ]]; then
    reply="${default_value}"
  fi
  printf '%s\n' "${reply}"
}
