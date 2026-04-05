#!/usr/bin/env bash

set -euo pipefail

SECRETS_POLICY_FILE="${SECRETS_REPO_ROOT}/flake/secrets-policy.nix"
SECRETS_POLICY_TOOL="${SECRETS_SCRIPT_DIR}/secrets-lib/policy.py"

secrets_load_policy_json() {
  if [[ -z "${SECRETS_POLICY_JSON:-}" ]]; then
    SECRETS_POLICY_JSON="$(
      nix eval --json --file "${SECRETS_POLICY_FILE}"
    )"
  fi
}

secrets_policy_tool() {
  secrets_load_policy_json
  SECRETS_POLICY_JSON="${SECRETS_POLICY_JSON}" python3 "${SECRETS_POLICY_TOOL}" "$@"
}

secrets_render_sops_config() {
  nix eval --raw --file "${SECRETS_SCRIPT_DIR}/secrets-lib/render-sops-config.nix"
}

secrets_sync_sops_config() {
  local rendered
  rendered="$(secrets_render_sops_config)"
  printf '%s' "${rendered}" > "${SECRETS_SOPS_CONFIG}"
}
