#!/usr/bin/env bash

set -euo pipefail

workflow_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_dir="$(cd "${workflow_dir}/.." && pwd)"

# shellcheck source=../secrets-lib/inspect.sh
source "${script_dir}/secrets-lib/inspect.sh"
# shellcheck source=../secrets-lib/ui.sh
source "${script_dir}/secrets-lib/ui.sh"

usage() {
  cat <<'EOF'
Usage: scripts/secrets create [options]

Create a new encrypted secret in an existing policy scope.

Options:
  --scope NAME      Scope name such as users.djoolz, services.fleet-test,
                    or machines.centauri
  --name FILENAME   Target file name relative to the chosen scope directory
  --editor CMD      Override $EDITOR for the plaintext editing step
  --template TYPE   empty, yaml, json, env, or ini
  --yes             Skip confirmation prompts
  -h, --help        Show this help
EOF
}

scope_name=""
target_name=""
editor_cmd="${EDITOR:-}"
template_type=""
assume_yes=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      scope_name="${2:?missing value for --scope}"
      shift 2
      ;;
    --name)
      target_name="${2:?missing value for --name}"
      shift 2
      ;;
    --editor)
      editor_cmd="${2:?missing value for --editor}"
      shift 2
      ;;
    --template)
      template_type="${2:?missing value for --template}"
      shift 2
      ;;
    --yes)
      assume_yes=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${editor_cmd}" ]]; then
  editor_cmd="vi"
fi

secrets_load_policy_json

if [[ -z "${scope_name}" ]]; then
  mapfile -t available_scopes < <(secrets_policy_tool list-scopes)
  if [[ "${#available_scopes[@]}" -eq 0 ]]; then
    secrets_ui_error "No scopes are defined in ${SECRETS_POLICY_FILE}"
    exit 1
  fi
  scope_name="$(secrets_ui_choose "Choose the target scope:" "${available_scopes[@]}")"
fi

case "${scope_name}" in
  users.*)
    scope_kind="users"
    scope_id="${scope_name#users.}"
    target_dir="${SECRETS_REPO_ROOT}/secrets/users/${scope_id}"
    default_name="secret.yaml"
    default_template="yaml"
    ;;
  services.*)
    scope_kind="services"
    scope_id="${scope_name#services.}"
    target_dir="${SECRETS_REPO_ROOT}/secrets/services/${scope_id}"
    default_name="secret.env"
    default_template="env"
    ;;
  machines.*)
    scope_kind="machines"
    scope_id="${scope_name#machines.}"
    target_dir="${SECRETS_REPO_ROOT}/secrets/machines/${scope_id}"
    default_name="secret.env"
    default_template="env"
    ;;
  *)
    secrets_ui_error "Unknown scope: ${scope_name}"
    exit 1
    ;;
esac

if [[ -z "${target_name}" ]]; then
  target_name="$(secrets_ui_prompt "Enter the target filename" "${default_name}")"
fi

case "${target_name}" in
  */* | "" | "." | "..")
    secrets_ui_error "Target file name must be a single relative file name."
    exit 1
    ;;
esac

file_ext="${target_name##*.}"
if [[ "${file_ext}" == "${target_name}" ]]; then
  secrets_ui_error "Target file name must include an extension such as .yaml, .json, .env, or .ini."
  exit 1
fi

case "${file_ext}" in
  yaml|yml)
    sops_type="yaml"
    inferred_template="yaml"
    ;;
  json)
    sops_type="json"
    inferred_template="json"
    ;;
  env)
    sops_type="dotenv"
    inferred_template="env"
    ;;
  ini)
    sops_type="ini"
    inferred_template="ini"
    ;;
  *)
    secrets_ui_error "Unsupported extension: .${file_ext}"
    exit 1
    ;;
esac

if [[ -z "${template_type}" ]]; then
  template_type="${inferred_template:-${default_template}}"
fi

case "${template_type}" in
  empty|yaml|json|env|ini)
    ;;
  *)
    secrets_ui_error "Unknown template type: ${template_type}"
    exit 1
    ;;
esac

target_path="${target_dir}/${target_name}"
relative_target="${target_path#${SECRETS_REPO_ROOT}/}"

if [[ -e "${target_path}" ]]; then
  secrets_ui_error "Target already exists: ${relative_target}"
  exit 1
fi

template_content=""
case "${template_type}" in
  yaml)
    template_content=$'# Fill in secret values.\nsecret: replace-me\n'
    ;;
  json)
    template_content=$'{\n  "secret": "replace-me"\n}\n'
    ;;
  env)
    example_path="${target_dir}/example.env.example"
    if [[ -f "${example_path}" ]]; then
      template_content="$(cat "${example_path}")"
      if [[ "${template_content}" != *$'\n' ]]; then
        template_content+=$'\n'
      fi
    else
      template_content=$'EXAMPLE_SECRET=replace-me\n'
    fi
    ;;
  ini)
    template_content=$'[default]\nsecret = replace-me\n'
    ;;
  empty)
    template_content=""
    ;;
esac

tmp_plaintext="$(mktemp)"
cleanup() {
  rm -f "${tmp_plaintext}"
}
trap cleanup EXIT

printf '%s' "${template_content}" > "${tmp_plaintext}"

secrets_ui_section "Create Secret"
secrets_ui_kv "Scope" "${scope_name}"
secrets_ui_kv "Target" "${relative_target}"
secrets_ui_kv "Format" "${sops_type}"
secrets_ui_kv "Editor" "${editor_cmd}"
printf '\n'

if [[ "${assume_yes}" -ne 1 ]] && ! secrets_ui_confirm "Open the plaintext template in ${editor_cmd} and encrypt it to ${relative_target}?"; then
  printf 'Aborted.\n'
  exit 1
fi

mkdir -p "${target_dir}"
"${editor_cmd}" "${tmp_plaintext}"

if [[ ! -s "${tmp_plaintext}" ]]; then
  secrets_ui_error "Refusing to encrypt an empty secret file."
  exit 1
fi

SOPS_AGE_KEY_FILE="${SECRETS_OPERATOR_KEY_FILE}" \
  sops --encrypt \
  --filename-override "${relative_target}" \
  --input-type "${sops_type}" \
  --output-type "${sops_type}" \
  --output "${target_path}" \
  "${tmp_plaintext}"

printf 'Wrote encrypted secret to %s\n' "${relative_target}"
