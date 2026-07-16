#!/usr/bin/env bash
# Comprehensive validation script for NixOS flake configuration.
#
# Usage:
#   sh validate.sh              # Run validation checks
#   sh validate.sh --dconf2nix  # Also regenerate dconf.nix from system settings
#   sh validate.sh --full-secrets
#                             # Allow privileged local host-key inspection

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=secrets-lib/inspect.sh
source "${script_dir}/secrets-lib/inspect.sh"

echo "=== NixOS Flake Configuration Validation ==="
echo ""

REGENERATE_DCONF=0
FULL_SECRETS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dconf2nix)
      REGENERATE_DCONF=1
      echo "⚠️  --dconf2nix flag detected: Will regenerate dconf.nix"
      echo ""
      shift
      ;;
    --full-secrets)
      FULL_SECRETS=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

FAILED=0
FAILED_CHECKS=()
REMOTE_VSCODE_HOSTS=(
  "mirach"
  "albaldah"
  "alhena"
)
MONITORING_INVENTORY_JSON=""
MONITORING_DOCKER_HOSTS=()

run_check() {
  local description="$1"
  shift

  if "$@"; then
    return 0
  fi

  echo "  ✗ ${description}"
  FAILED=$((FAILED + 1))
  FAILED_CHECKS+=("${description}")
  return 0
}
run_quiet_check() {
  local success_description="$1"
  local failure_description="$2"
  shift 2

  if "$@"; then
    echo "  ✓ ${success_description}"
    return 0
  fi

  echo "  ✗ ${failure_description}"
  FAILED=$((FAILED + 1))
  FAILED_CHECKS+=("${failure_description}")
  return 0
}


# shellcheck disable=SC2329 # Invoked indirectly through run_check below.
validate_remote_vscode_support() {
  local host_name="$1"
  local nix_ld_enabled

  if ! nix_ld_enabled="$(
    nix eval ".#nixosConfigurations.${host_name}.config.programs.nix-ld.enable" 2>/dev/null
  )"; then
    echo "  ✗ ${host_name}: failed to evaluate programs.nix-ld.enable"
    return 1
  fi

  if [[ "${nix_ld_enabled}" != "true" ]]; then
    echo "  ✗ ${host_name}: programs.nix-ld.enable = ${nix_ld_enabled}"
    return 1
  fi

  echo "  ✓ ${host_name}: VS Code Remote support enabled"
}

# shellcheck disable=SC2329 # Invoked indirectly through run_check below.
validate_docker_journald_logging() {
  local host_name="$1"
  local log_driver

  if ! log_driver="$(
    nix eval ".#nixosConfigurations.${host_name}.config.virtualisation.docker.daemon.settings.log-driver" 2>/dev/null | tr -d '"'
  )"; then
    echo "  ✗ ${host_name}: failed to evaluate docker log-driver"
    return 1
  fi

  if [[ "${log_driver}" != "journald" ]]; then
    echo "  ✗ ${host_name}: docker log-driver = ${log_driver}"
    return 1
  fi

  echo "  ✓ ${host_name}: docker log-driver = journald"
}

# shellcheck disable=SC2329 # Invoked indirectly through run_check below.
validate_albaldah_traefik_acquisition() {
  local acquisitions_json

  if ! acquisitions_json="$(
    nix eval --json ".#nixosConfigurations.albaldah.config.services.crowdsec.localConfig.acquisitions" 2>/dev/null
  )"; then
    echo "  ✗ albaldah: failed to evaluate CrowdSec acquisitions"
    return 1
  fi

  if ! grep -Fq '"/var/log/traefik/access.log"' <<<"${acquisitions_json}" \
    || ! grep -Fq '"type":"traefik"' <<<"${acquisitions_json}"; then
    echo "  ✗ albaldah: missing /var/log/traefik/access.log CrowdSec acquisition"
    return 1
  fi

  echo "  ✓ albaldah: CrowdSec Traefik acquisition uses /var/log/traefik/access.log"
}

# shellcheck disable=SC2329 # Invoked indirectly through run_check below.
validate_local_prometheus_exporter() {
  local host_name="$1"
  local exporter_name="$2"
  local expected_port="$3"
  local expected_default_address="$4"
  local enabled
  local port
  local address
  local expected_address="${expected_default_address}"

  if [[ " ${MONITORING_DOCKER_HOSTS[*]} " == *" ${host_name} "* ]]; then
    expected_address="0.0.0.0"
  fi

  if ! enabled="$(
    nix eval ".#nixosConfigurations.${host_name}.config.services.prometheus.exporters.${exporter_name}.enable" 2>/dev/null
  )"; then
    echo "  ✗ ${host_name}: failed to evaluate ${exporter_name} exporter enable flag"
    return 1
  fi

  if [[ "${enabled}" != "true" ]]; then
    echo "  ✗ ${host_name}: ${exporter_name} exporter enable = ${enabled}"
    return 1
  fi

  if ! port="$(
    nix eval ".#nixosConfigurations.${host_name}.config.services.prometheus.exporters.${exporter_name}.port" 2>/dev/null
  )"; then
    echo "  ✗ ${host_name}: failed to evaluate ${exporter_name} exporter port"
    return 1
  fi

  if [[ "${port}" != "${expected_port}" ]]; then
    echo "  ✗ ${host_name}: ${exporter_name} exporter port = ${port}"
    return 1
  fi

  if ! address="$(
    nix eval ".#nixosConfigurations.${host_name}.config.services.prometheus.exporters.${exporter_name}.listenAddress" 2>/dev/null | tr -d '"'
  )"; then
    echo "  ✗ ${host_name}: failed to evaluate ${exporter_name} exporter listenAddress"
    return 1
  fi

  if [[ "${address}" != "${expected_address}" ]]; then
    echo "  ✗ ${host_name}: ${exporter_name} exporter listenAddress = ${address}"
    return 1
  fi

  echo "  ✓ ${host_name}: ${exporter_name} exporter listens on ${expected_address}:${expected_port}"
}

# shellcheck disable=SC2329 # Invoked indirectly through run_check below.
validate_journald_retention() {
  local host_name="$1"
  local extra_config

  if ! extra_config="$(
    nix eval ".#nixosConfigurations.${host_name}.config.services.journald.extraConfig" 2>/dev/null | tr -d '"'
  )"; then
    echo "  ✗ ${host_name}: failed to evaluate journald extraConfig"
    return 1
  fi

  if ! grep -Fq "SystemMaxUse=1G" <<<"${extra_config}"; then
    echo "  ✗ ${host_name}: missing SystemMaxUse=1G in journald config"
    return 1
  fi

  if ! grep -Fq "MaxRetentionSec=7day" <<<"${extra_config}"; then
    echo "  ✗ ${host_name}: missing MaxRetentionSec=7day in journald config"
    return 1
  fi

  echo "  ✓ ${host_name}: journald retention uses 1G / 7day limits"
}

# shellcheck disable=SC2329 # Invoked indirectly through run_check below.
validate_monitoring_inventory() {
  local inventory_json

  if [[ -n "${MONITORING_INVENTORY_JSON}" ]]; then
    inventory_json="${MONITORING_INVENTORY_JSON}"
  elif ! inventory_json="$(
    nix eval --json .#monitoringInventory 2>/dev/null
  )"; then
    echo "  ✗ monitoring inventory failed to evaluate"
    return 1
  fi

  if ! jq -e '
    (.hosts | keys == ["albaldah", "centauri", "mirach"]) and
    (.groups.all_hosts == ["albaldah", "centauri", "mirach"]) and
    (.groups.public_edge_hosts == ["albaldah"]) and
    (.groups.docker_hosts == ["albaldah", "centauri", "mirach"]) and
    (.groups.frontend_hosts == ["albaldah", "centauri"]) and
    (.groups.monitoring_hosts == ["albaldah"]) and
    (.groups.security_hosts == ["albaldah"]) and
    (all(.hosts[]; has("exposure_tier") and has("capabilities") and has("service_roles") and has("monitoring_enabled"))) and
    (.hosts.albaldah.exposure_tier == "public_edge") and
    (.hosts.albaldah.service_roles == ["edge", "monitoring", "security", "frontend"]) and
    (.hosts.centauri.exposure_tier == "tailscale_only") and
    (.hosts.centauri.service_roles == ["frontend"]) and
    (.hosts.mirach.exposure_tier == "lan_only") and
    (.hosts.mirach.service_roles == ["infra", "vm_host"])
  ' <<<"${inventory_json}" >/dev/null; then
    echo "  ✗ monitoring inventory contents do not match the current fleet contract"
    return 1
  fi

  echo "  ✓ monitoring inventory export matches the current three-host fleet"
}

echo "Shell:"
run_quiet_check "shell lint passed" "shell lint failed" \
  bash "${script_dir}/lint-shell.sh"

echo ""
echo "Nix:"
run_quiet_check "Nix lint passed" "Nix lint failed" \
  bash "${script_dir}/lint-nix.sh"

echo ""
echo "Documentation:"
run_quiet_check "markdown lint passed" "markdown lint failed" \
  bash "${script_dir}/lint-markdown.sh"

echo ""
if [[ "${REGENERATE_DCONF}" -eq 1 ]]; then
  echo "Regenerating dconf.nix:"
  dconf_file="modules/home/dconf/dconf.nix"

  if ! command -v dconf2nix > /dev/null 2>&1; then
    echo "  ✗ dconf2nix not found. Install with: nix-shell -p dconf2nix"
    FAILED=$((FAILED + 1))
  else
    dconf_temp="$(mktemp)"
    if [[ -f "${dconf_file}" ]]; then
      cp "${dconf_file}" "${dconf_temp}"
    fi

    dconf dump / | dconf2nix > "${dconf_file}"
    echo "  ✓ Regenerated ${dconf_file}"

    if [[ -f "${dconf_temp}" ]]; then
      diff_count="$(diff "${dconf_temp}" "${dconf_file}" | wc -l || true)"
      if [[ "${diff_count}" -gt 0 ]]; then
        echo "  Changes detected (${diff_count} lines):"
        diff -u "${dconf_temp}" "${dconf_file}" 2>/dev/null | head -30 || true
        if [[ "${diff_count}" -gt 30 ]]; then
          echo "     ... and $(("${diff_count}" - 30)) more lines"
        fi
      else
        echo "  ✓ No changes detected"
      fi
    fi
    rm -f "${dconf_temp}"
    echo ""
  fi
fi

echo "Flake Structure:"
if nix flake show > /dev/null 2>&1; then
  echo "  ✓ nix flake show succeeds"
else
  echo "  ✗ nix flake show failed"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "NixOS Configurations:"

MONITORING_INVENTORY_JSON="$(nix eval --raw .#monitoringInventoryJson 2>/dev/null || true)"
if [[ -n "${MONITORING_INVENTORY_JSON}" ]]; then
  mapfile -t MONITORING_DOCKER_HOSTS < <(
    jq -r '.groups.docker_hosts[]' <<<"${MONITORING_INVENTORY_JSON}"
  )
fi

run_check "monitoring inventory export failed to evaluate" \
  validate_monitoring_inventory

echo "  Centauri:"
echo "    - desktop: gnome ($(nix eval .#nixosConfigurations.centauri.config.services.desktopManager.gnome.enable 2>/dev/null))"
echo "    - docker: $(nix eval .#nixosConfigurations.centauri.config.virtualisation.docker.enable 2>/dev/null)"
echo "    - system evaluates: ✓"

echo "  Mirach:"
echo "    - hostname: $(nix eval .#nixosConfigurations.mirach.config.networking.hostName 2>/dev/null | tr -d '"')"
echo "    - libvirtd: $(nix eval .#nixosConfigurations.mirach.config.virtualisation.libvirtd.enable 2>/dev/null)"
echo "    - docker: $(nix eval .#nixosConfigurations.mirach.config.virtualisation.docker.enable 2>/dev/null)"
echo "    - system evaluates: ✓"

echo "  Albaldah:"
echo "    - hostname: $(nix eval .#nixosConfigurations.albaldah.config.networking.hostName 2>/dev/null | tr -d '"')"
echo "    - networkmanager: $(nix eval .#nixosConfigurations.albaldah.config.networking.networkmanager.enable 2>/dev/null)"
echo "    - tailscale: $(nix eval .#nixosConfigurations.albaldah.config.services.tailscale.enable 2>/dev/null)"
echo "    - system evaluates: ✓"

echo ""
echo "Remote VS Code Support:"
for host_name in "${REMOTE_VSCODE_HOSTS[@]}"; do
  run_check "remote VS Code support missing for ${host_name}" \
    validate_remote_vscode_support "${host_name}"
done

echo ""
echo "Docker Logging:"
for host_name in "${MONITORING_DOCKER_HOSTS[@]}"; do
  run_check "docker journald logging missing for ${host_name}" \
    validate_docker_journald_logging "${host_name}"
done
run_check "albaldah CrowdSec Traefik acquisition drifted" \
  validate_albaldah_traefik_acquisition

echo ""
echo "Monitoring Baseline:"
for host_name in "${MONITORING_DOCKER_HOSTS[@]}"; do
  run_check "node exporter missing or drifted for ${host_name}" \
    validate_local_prometheus_exporter "${host_name}" node 9100 127.0.0.1
  run_check "systemd exporter missing or drifted for ${host_name}" \
    validate_local_prometheus_exporter "${host_name}" systemd 9558 127.0.0.1
  run_check "journald retention drifted for ${host_name}" \
    validate_journald_retention "${host_name}"
done

echo ""
echo "Home-Manager Configurations:"
if nix eval ".#homeConfigurations.\"djoolz@gnome\".activationPackage" > /dev/null 2>&1; then
  echo "  ✓ djoolz@gnome evaluates"
else
  echo "  ✗ djoolz@gnome failed"
  FAILED=$((FAILED + 1))
fi

echo ""
if bash "$(dirname "$0")/test-system-shell-and-cli-tooling.sh"; then
  :
else
  FAILED=$((FAILED + 1))
fi

echo ""
echo "Secrets Policy:"
run_check "scripts/secrets validate-policy failed" \
  bash "${script_dir}/secrets" validate-policy
run_check "scripts/secrets sync-policy --check failed" \
  bash "${script_dir}/secrets" sync-policy --check

echo ""
echo "Secrets Access:"
secrets_load_policy_json
mapfile -t policy_hosts < <(secrets_policy_tool list-hosts)
validate_access_args=()
if [[ "${FULL_SECRETS}" -eq 1 ]]; then
  validate_access_args+=(--full-test)
fi

if [[ "${#policy_hosts[@]}" -eq 0 ]]; then
  echo "  ✗ No hosts defined in flake/secrets-policy.nix"
  FAILED=$((FAILED + 1))
else
  for host_name in "${policy_hosts[@]}"; do
    echo "  Operator access for ${host_name}:"
    run_check "operator access validation failed for ${host_name}" \
      bash "${script_dir}/secrets" validate-access "${validate_access_args[@]}" --actor operator --host "${host_name}"
  done
fi

current_host="$(hostname -s)"
if printf '%s\n' "${policy_hosts[@]:-}" | grep -Fxq "${current_host}"; then
  echo "  Local host access for ${current_host}:"
  run_check "local host access validation failed for ${current_host}" \
    bash "${script_dir}/secrets" validate-access "${validate_access_args[@]}" --actor host --host "${current_host}"
else
  echo "  Local host access: skipped (${current_host} is not in flake/secrets-policy.nix)"
fi


echo ""
if [[ "${FAILED}" -eq 0 ]]; then
  echo "=== ✓ All Validation Tests Passed ==="
  exit 0
else
  echo "Failed checks:"
  printf '  - %s\n' "${FAILED_CHECKS[@]}"
  echo "=== ✗ Validation Failed (${FAILED} tests) ==="
  exit 1
fi
