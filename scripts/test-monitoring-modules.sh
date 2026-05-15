#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "${repo_root}"

MODE="static"
if [[ "${1:-}" == "--live" ]]; then
  MODE="live"
fi

fail() {
  printf '  ✗ %s\n' "$1"
  exit 1
}

pass() {
  printf '  ✓ %s\n' "$1"
}

assert_rg() {
  local pattern="$1"
  local path="$2"
  local message="$3"

  if rg -q --multiline "${pattern}" "${path}"; then
    pass "${message}"
  else
    fail "${message}"
  fi
}

assert_cmd_contains() {
  local cmd="$1"
  local needle="$2"
  local message="$3"
  local output

  if ! output="$(bash -lc "${cmd}" 2>&1)"; then
    fail "${message} (command failed: ${cmd}; output: ${output})"
  fi

  if grep -Fq "${needle}" <<<"${output}"; then
    pass "${message}"
  else
    fail "${message} (missing '${needle}' in output of: ${cmd})"
  fi
}

probe_port() {
  local port="$1"
  local label="$2"
  local ss_output

  ss_output="$(bash -lc "ss -ltnp | rg -n '(:${port}\\b|Local Address|LISTEN)' || true")"
  if grep -Fq ":${port}" <<<"${ss_output}"; then
    pass "${label} is physically listening on TCP ${port}"
    return 0
  fi

  printf '  debug: ss -ltnp (filtered for %s)\n' "${port}"
  if [[ -n "${ss_output}" ]]; then
    printf '%s\n' "${ss_output}" | sed 's/^/    /'
  else
    printf '    <no matching listeners>\n'
  fi

  fail "${label} is physically listening on TCP ${port}"
}

run_static_checks() {
  echo "Monitoring module regression checks (static):"

assert_rg 'imports = \[ \./docker-options\.nix \./monitoring-docker-scrape-access\.nix \];' \
  modules/nixos/virtualisation/docker.nix \
  "docker.nix still imports monitoring-docker-scrape-access"

assert_rg '../../modules/nixos/services/monitoring-baseline\.nix' \
  flake/machines/servers.nix \
  "server flake definitions still import monitoring-baseline"

assert_rg 'node = \{\s+enable = true;\s+port = 9100;\s+listenAddress = "0\.0\.0\.0";' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps node exporter bound to 0.0.0.0:9100"

assert_rg 'systemd = \{\s+enable = true;\s+port = 9558;\s+listenAddress = "0\.0\.0\.0";' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps systemd exporter bound to 0.0.0.0:9558"

assert_rg 'journald\.audit = true;' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps journald audit enabled"

assert_rg 'SystemMaxUse=1G' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps journald size retention"

assert_rg 'MaxRetentionSec=7day' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps journald time retention"

assert_rg 'security = \{\s+audit = \{\s+enable = true;' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps Linux audit enabled"

assert_rg 'auditd\.enable = true;' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps auditd enabled"

assert_rg '/home/djoolz/docker/' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps docker compose audit watch"

assert_rg 'docker_config' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps docker config audit watch"

assert_rg 'docker_sock' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps docker socket audit watch"

assert_rg 'firewall_config' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps firewall config audit watch"

assert_rg 'root_exec' \
  modules/nixos/services/monitoring-baseline.nix \
  "monitoring-baseline keeps privileged exec audit rule"

assert_rg 'node\.listenAddress = lib\.mkForce "0\.0\.0\.0";' \
  modules/nixos/virtualisation/monitoring-docker-scrape-access.nix \
  "docker scrape access forces node exporter to 0.0.0.0"

assert_rg 'systemd\.listenAddress = lib\.mkForce "0\.0\.0\.0";' \
  modules/nixos/virtualisation/monitoring-docker-scrape-access.nix \
  "docker scrape access forces systemd exporter to 0.0.0.0"

assert_rg 'networking\.firewall\.interfaces\.tailscale0\.allowedTCPPorts = \[[^]]*9100[^]]*9558[^]]*\];' \
  modules/nixos/virtualisation/monitoring-docker-scrape-access.nix \
  "docker scrape access keeps Tailscale-only firewall allowance for exporter ports"

  echo "All static monitoring module checks passed."
}

run_live_checks() {
  echo "Monitoring module regression checks (live runtime):"
  probe_port "9100" "node exporter port"
  probe_port "9558" "systemd exporter port"

  assert_cmd_contains "sudo systemd-analyze cat-config systemd/journald.conf" "SystemMaxUse=1G" \
    "journald runtime config keeps SystemMaxUse=1G"
  assert_cmd_contains "sudo systemd-analyze cat-config systemd/journald.conf" "MaxRetentionSec=7day" \
    "journald runtime config keeps MaxRetentionSec=7day"

  assert_cmd_contains "sudo auditctl -s" "enabled 1" "audit subsystem is enabled"
  assert_cmd_contains "sudo systemctl is-enabled auditd.service" "enabled" \
    "auditd service is enabled"
  assert_cmd_contains "sudo systemctl is-active auditd.service" "active" \
    "auditd service is active"
  assert_cmd_contains "sudo auditctl -l" "docker_compose" \
    "audit runtime rules include docker compose watch"
  assert_cmd_contains "sudo auditctl -l" "docker_config" \
    "audit runtime rules include docker config watch"
  assert_cmd_contains "sudo auditctl -l" "docker_sock" \
    "audit runtime rules include docker socket watch"
  assert_cmd_contains "sudo auditctl -l" "firewall_config" \
    "audit runtime rules include firewall config watch"

  assert_cmd_contains "sudo nft list ruleset" "9100, 9558" \
    "firewall runtime rules include monitoring exporter ports"
  assert_cmd_contains "sudo nft list ruleset" "tailscale0" \
    "firewall runtime rules include tailscale0 interface rule for monitoring ports"

  echo "All live monitoring module checks passed."
}

if [[ "${MODE}" == "live" ]]; then
  run_live_checks
else
  run_static_checks
fi
