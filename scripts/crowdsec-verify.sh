#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/crowdsec-verify.sh

Read-only CrowdSec health check for hosts using this repo's CrowdSec wiring.
Checks core services, local listeners, bouncer registration, and Docker chain.
Exits nonzero if any required check fails.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 0 ]]; then
  printf 'Unknown argument: %s\n\n' "$1" >&2
  usage >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  sudo_cmd=()
else
  sudo_cmd=(sudo)
fi

failed=0

check() {
  local description="$1"
  shift

  if "$@"; then
    printf '  [ok] %s\n' "$description"
  else
    printf '  [fail] %s\n' "$description"
    failed=$((failed + 1))
  fi
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
unit_loaded() {
  "${sudo_cmd[@]}" systemctl show --property LoadState --value "$1" 2>/dev/null | grep -Fxq "loaded"
}

# shellcheck disable=SC2329 # Invoked indirectly through check_service_unit().
unit_active() {
  "${sudo_cmd[@]}" systemctl is-active --quiet "$1"
}

# shellcheck disable=SC2329 # Invoked indirectly through check_oneshot_unit().
unit_not_failed() {
  ! "${sudo_cmd[@]}" systemctl is-failed --quiet "$1"
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_service_unit() {
  local unit="$1"
  unit_loaded "$unit" && unit_active "$unit"
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_oneshot_unit() {
  local unit="$1"
  unit_loaded "$unit" && unit_not_failed "$unit"
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_lapi_health() {
  "${sudo_cmd[@]}" curl -fsS http://127.0.0.1:8080/health >/dev/null
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_appsec_listener() {
  local http_code
  http_code="$("${sudo_cmd[@]}" curl -sS -o /dev/null -w '%{http_code}' -X POST -d '{}' http://127.0.0.1:7422/ || true)"
  [[ "$http_code" != "000" && -n "$http_code" ]]
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_console_status() {
  "${sudo_cmd[@]}" cscli console status >/dev/null
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_capi_status() {
  "${sudo_cmd[@]}" cscli capi status >/dev/null
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_metrics() {
  "${sudo_cmd[@]}" cscli metrics >/dev/null
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_bouncer_registration() {
  "${sudo_cmd[@]}" cscli bouncers list | grep -Fq "crowdsec-firewall-bouncer"
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_docker_user_chain() {
  "${sudo_cmd[@]}" iptables -S DOCKER-USER 2>/dev/null | grep -Fq "CROWDSEC_CHAIN"
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_docker_log_driver() {
  docker info --format '{{.LoggingDriver}}' 2>/dev/null | grep -Fxq "journald"
}

# shellcheck disable=SC2329 # Invoked indirectly through check().
check_traefik_access_log_path() {
  "${sudo_cmd[@]}" test -r /var/log/traefik/access.log
}

printf 'CrowdSec verify\n'
printf 'host: %s\n' "$(hostname -s)"
printf '\n'

printf 'Services:\n'
check "crowdsec.service active" check_service_unit crowdsec.service
check "crowdsec-firewall-bouncer.service active" check_service_unit crowdsec-firewall-bouncer.service
check "crowdsec-console-enroll.service not failed" check_oneshot_unit crowdsec-console-enroll.service
check "crowdsec-capi-register.service not failed" check_oneshot_unit crowdsec-capi-register.service
check "crowdsec-firewall-bouncer-register.service not failed" check_oneshot_unit crowdsec-firewall-bouncer-register.service

printf '\n'
printf 'Listeners:\n'
check "LAPI health on 127.0.0.1:8080" check_lapi_health
check "AppSec reachable on 127.0.0.1:7422" check_appsec_listener

printf '\n'
printf 'CrowdSec state:\n'
check "Console status readable" check_console_status
check "CAPI status readable" check_capi_status
check "Metrics readable" check_metrics
check "Firewall bouncer registered" check_bouncer_registration

printf '\n'
printf 'Firewall:\n'
check "DOCKER-USER jumps into CrowdSec chain" check_docker_user_chain

printf '\n'
printf 'Traefik acquisition:\n'
check "Docker log driver is journald" check_docker_log_driver
check "Traefik access log readable at /var/log/traefik/access.log" check_traefik_access_log_path

printf '\n'
if [[ "$failed" -eq 0 ]]; then
  printf 'Result: ok\n'
  exit 0
fi

printf 'Result: fail (%s checks)\n' "$failed"
exit 1
