#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/../.." && pwd)"
policy_tool="${repo_root}/scripts/secrets-lib/policy.py"
policy_file="${repo_root}/flake/secrets-policy.nix"
cache_root="$(mktemp -d)"

failed=0
failed_checks=()
skipped=0

cleanup() {
  rm -rf "${cache_root}"
}

trap cleanup EXIT

run_check() {
  local description="$1"
  local status=0
  shift

  if "$@"; then
    status=0
  else
    status=$?
  fi

  if [[ "${status}" -eq 0 ]]; then
    printf '  %s\n' "PASS: ${description}"
    return 0
  fi

  if [[ "${status}" -eq 125 ]]; then
    printf '  %s\n' "SKIP: ${description}"
    skipped=$((skipped + 1))
    return 0
  fi

  printf '  %s\n' "FAIL: ${description}"
  failed=$((failed + 1))
  failed_checks+=("${description}")
  return 0
}

assert_contains() {
  local file_path="$1"
  local needle="$2"
  grep -Fq "${needle}" "${file_path}"
}

assert_not_contains() {
  local file_path="$1"
  local needle="$2"
  if grep -Fq "${needle}" "${file_path}"; then
    return 1
  fi
}

test_py_compile() {
  python3 -m py_compile "${policy_tool}"
}

test_validate_policy() {
  bash "${repo_root}/scripts/secrets-workflows/validate-policy.sh"
}

test_sync_policy_check() {
  bash "${repo_root}/scripts/secrets" sync-policy --check
}

test_nix_eval_centauri() {
  local output=""
  if output="$(XDG_CACHE_HOME="${cache_root}" nix eval .#nixosConfigurations.centauri.config.system.build.toplevel 2>&1)"; then
    return 0
  fi
  if grep -Fq "/nix/var/nix/daemon-socket/socket" <<< "${output}"; then
    return 125
  fi
  printf '%s\n' "${output}" >&2
  return 1
}

test_nix_eval_home_workstation() {
  local output=""
  if output="$(XDG_CACHE_HOME="${cache_root}" nix eval '.#homeConfigurations."djoolz@workstation".activationPackage' 2>&1)"; then
    return 0
  fi
  if grep -Fq "/nix/var/nix/daemon-socket/socket" <<< "${output}"; then
    return 125
  fi
  printf '%s\n' "${output}" >&2
  return 1
}

test_set_existing_user_scope_hosts() {
  local tmp
  tmp="$(mktemp)"
  cp "${policy_file}" "${tmp}"
  python3 "${policy_tool}" \
    set-user-scope-hosts \
    --policy-file "${tmp}" \
    --user djoolz \
    --host albaldah \
    --host centauri \
    --host mirach

  assert_contains "${tmp}" 'djoolz = { hosts = [ "albaldah" "centauri" "mirach" ]; };'
  assert_contains "${tmp}" 'fleet-test = { hosts = [ "albaldah" "alhena" "centauri" "mirach" ]; };'
}

test_create_user_scope_preserves_existing_scopes() {
  local tmp
  tmp="$(mktemp)"
  cp "${policy_file}" "${tmp}"
  python3 "${policy_tool}" \
    set-user-scope-hosts \
    --policy-file "${tmp}" \
    --user newscope \
    --host albaldah \
    --create

  assert_contains "${tmp}" 'djoolz = { hosts = [ "albaldah" "alhena" "centauri" "mirach" ]; };'
  assert_contains "${tmp}" 'newscope = { hosts = [ "albaldah" ]; };'
  assert_contains "${tmp}" 'fleet-test = { hosts = [ "albaldah" "alhena" "centauri" "mirach" ]; };'
}

test_remove_user_scope_preserves_other_sections() {
  local tmp
  tmp="$(mktemp)"
  cp "${policy_file}" "${tmp}"
  python3 "${policy_tool}" \
    set-user-scope-hosts \
    --policy-file "${tmp}" \
    --user newscope \
    --host albaldah \
    --create
  python3 "${policy_tool}" \
    remove-user-scope \
    --policy-file "${tmp}" \
    --user newscope

  assert_not_contains "${tmp}" 'newscope = { hosts = [ "albaldah" ]; };'
  assert_contains "${tmp}" 'djoolz = { hosts = [ "albaldah" "alhena" "centauri" "mirach" ]; };'
  assert_contains "${tmp}" 'fleet-test = { hosts = [ "albaldah" "alhena" "centauri" "mirach" ]; };'
}

test_set_host_recipient_preserves_class() {
  local tmp
  tmp="$(mktemp)"
  cp "${policy_file}" "${tmp}"
  python3 "${policy_tool}" \
    set-host-recipient \
    --policy-file "${tmp}" \
    --host albaldah \
    --recipient age1replacementrecipient

  assert_contains "${tmp}" '    albaldah = {'
  assert_contains "${tmp}" '        "age1replacementrecipient";'
  assert_contains "${tmp}" '      class = "homelab";'
}

test_create_host_adds_entry() {
  local tmp
  tmp="$(mktemp)"
  cp "${policy_file}" "${tmp}"
  python3 "${policy_tool}" \
    set-host-recipient \
    --policy-file "${tmp}" \
    --host rigel \
    --recipient age1rigelrecipient \
    --class-name workstation \
    --create

  assert_contains "${tmp}" '    rigel = {'
  assert_contains "${tmp}" '        "age1rigelrecipient";'
  assert_contains "${tmp}" '      class = "workstation";'
}

test_remove_host_updates_all_scope_memberships() {
  local tmp
  tmp="$(mktemp)"
  cp "${policy_file}" "${tmp}"
  python3 "${policy_tool}" \
    remove-host \
    --policy-file "${tmp}" \
    --host alhena

  assert_not_contains "${tmp}" '    alhena = {'
  assert_contains "${tmp}" 'djoolz = { hosts = [ "albaldah" "centauri" "mirach" ]; };'
  assert_contains "${tmp}" 'fleet-test = { hosts = [ "albaldah" "centauri" "mirach" ]; };'
}

main() {
  cd "${repo_root}"

  printf '%s\n' '=== Secrets Policy Roundtrip Tests ==='

  run_check "policy tool compiles" test_py_compile
  run_check "validate-policy succeeds" test_validate_policy
  run_check "sync-policy --check succeeds" test_sync_policy_check
  run_check "centauri evaluates" test_nix_eval_centauri
  run_check "home workstation evaluates" test_nix_eval_home_workstation

  printf '\n%s\n' 'Mutation tests:'
  run_check "existing user scope updates inline hosts" test_set_existing_user_scope_hosts
  run_check "creating user scope preserves existing scopes" test_create_user_scope_preserves_existing_scopes
  run_check "removing user scope preserves other sections" test_remove_user_scope_preserves_other_sections
  run_check "existing host recipient update preserves class" test_set_host_recipient_preserves_class
  run_check "creating host adds a new host entry" test_create_host_adds_entry
  run_check "removing host updates all shared scopes" test_remove_host_updates_all_scope_memberships

  if [[ "${failed}" -eq 0 ]]; then
    if [[ "${skipped}" -gt 0 ]]; then
      printf '\n%s\n' "=== PASS: all required secrets policy tests succeeded (${skipped} skipped) ==="
    else
      printf '\n%s\n' '=== PASS: all secrets policy tests succeeded ==='
    fi
    return 0
  fi

  printf '\n%s\n' 'Failed checks:'
  printf '  - %s\n' "${failed_checks[@]}"
  printf '%s\n' "=== FAIL: ${failed} secrets policy tests failed ==="
  return 1
}

main "$@"
