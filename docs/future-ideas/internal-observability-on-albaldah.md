# Internal Observability On `*.int.djoolz.de`

This note captures the planned observability layout for the `albaldah` VPS.

Most of this is still plan only. Host `auditd` wiring is now live in
`nixos/machines/albaldah/default.nix`; the rest of this note does not describe
a deployed state yet.

## Summary

Keep the current split:

- `/home/djoolz/nixos` keeps host wiring, firewall, Tailscale, CrowdSec, secrets
- `/home/djoolz/docker/stacks/traefik` keeps Traefik and current edge/security compose
- `/home/djoolz/docker/stacks/monitoring` will hold the new observability stack

Target access model:

- monitoring UIs are internal-only
- access goes through Tailscale, not the public internet
- routes live on dedicated subdomains under `int.djoolz.de`
- Authentik can be added later as a Traefik middleware change
- all UI routes are dev-time exposure and should be reduced later

Planned UI routes:

- `grafana.int.djoolz.de`
- `prometheus.int.djoolz.de`
- `loki.int.djoolz.de`
- `alerts.int.djoolz.de`

## Target Topology

```text
Traefik access/error logs ─┐
CrowdSec logs/metrics     ├─> Alloy ─> Loki
Docker logs               ┘

node_exporter      ─┐
systemd_exporter   ├─> Prometheus ─> Grafana + Alertmanager
Traefik metrics    ┤
CrowdSec metrics   ┘
```

Keep Traefik and CrowdSec where they are today. Add monitoring around them.

## Planned Changes

### Traefik

- keep Traefik in `/home/djoolz/docker/stacks/traefik`
- keep Traefik runtime logs on stdout/stderr and let Docker forward them to `journald`
- split Traefik access logs into a bind-mounted file path for HTTP event parsing
- set Traefik access logs to `json`
- add a dedicated Prometheus metrics entrypoint on `:8082`
- bind that metrics entrypoint to loopback only on the host
- keep metrics off the public internet
- use Prometheus labels for entrypoints, routers, and services
- reduce log level from current `DEBUG` to `INFO` unless debugging is active

Static-config target shape:

```yaml
entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"
  metrics:
    address: ":8082"

metrics:
  prometheus:
    entryPoint: metrics
    addEntryPointsLabels: true
    addRoutersLabels: true
    addServicesLabels: true

accessLog: {}

log:
  level: INFO
```

Access log target:

```yaml
accessLog:
  filePath: /logs/access.json
  format: json
```

Runtime log target:

```yaml
log:
  level: INFO
```

Compose shape:

```yaml
volumes:
  - ./data/traefik-logs:/logs
```

Compose exposure target:

```yaml
ports:
  - "80:80"
  - "443:443"
  - "127.0.0.1:8082:8082"
```

### CrowdSec

- keep CrowdSec host/security ownership in `/home/djoolz/nixos`
- keep current firewall bouncer behavior, including `DOCKER-USER`
- keep existing auth-domain separation unchanged
- acquire Traefik access logs from the bind-mounted Traefik access log file
- keep Docker `journald` logging as a repo-wide host baseline for container
  runtime logs and general observability
- scrape CrowdSec metrics directly from Prometheus
- expose metrics only on a non-public path
- monitor service health, decisions, and bouncer status

Expected scrape target:

```yaml
- job_name: crowdsec
  static_configs:
    - targets:
        - 127.0.0.1:6060
```

### Monitoring Stack

Create a separate compose project at `/home/djoolz/docker/stacks/monitoring`
with:

- Grafana
- Prometheus
- Loki
- Alloy
- `cadvisor`
- Alertmanager

Rules:

- attach the stack to Traefik's `proxy` network for routed UI access
- keep service ports internal unless a host-local scrape path is required
- persist Grafana, Prometheus, Loki, and Alertmanager state
- use bind-mounted stack-local folders, not Docker named volumes
- route UI containers through Traefik only

### Host Auditing

This part is no longer just idea. `albaldah` already runs host audit support
from `nixos/machines/albaldah/default.nix`.

Live host shape:

```nix
{
  security.audit.enable = true;
  security.auditd.enable = true;

  services.journald.audit = true;

  security.audit.rules = [
    "-w /etc/passwd -p wa -k identity"
    "-w /etc/group -p wa -k identity"
    "-w /etc/shadow -p wa -k identity"
    "-w /etc/gshadow -p wa -k identity"
    "-w /etc/sudoers -p wa -k sudoers"
    "-w /etc/sudoers.d/ -p wa -k sudoers"

    "-w /root/.ssh/ -p wa -k root_ssh"

    "-w /etc/systemd/system/ -p wa -k systemd_units"
    "-w /run/systemd/system/ -p wa -k systemd_runtime_units"

    "-w /etc/cron.d/ -p wa -k cron"
    "-w /etc/cron.daily/ -p wa -k cron"
    "-w /etc/crontab -p wa -k cron"

    "-w /etc/nixos/ -p wa -k nixos_config"
    "-w /home/djoolz/docker/ -p wa -k docker_compose"

    "-a always,exit -F arch=b64 -S execve -F euid=0 -k root_exec"
    "-a always,exit -F arch=b64 -S execve -F auid>=1000 -F auid!=unset -k user_exec"
    "-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k kernel_modules"

    "-a always,exit -F arch=b64 -S openat,creat,truncate,ftruncate -F exit=-EACCES -k access_denied"
    "-a always,exit -F arch=b64 -S openat,creat,truncate,ftruncate -F exit=-EPERM -k access_denied"

    "-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time_change"
    "-a always,exit -F arch=b64 -S sethostname,setdomainname -k hostname_change"
  ];
}
```

What live rules cover:

- identity file changes: passwd, group, shadow, sudoers
- root SSH material changes under `/root/.ssh/`
- systemd unit changes in `/etc/systemd/system/` and `/run/systemd/system/`
- cron changes
- repo-owned config changes in `/etc/nixos/` and `/home/djoolz/docker/`
- root command execution via `execve` with `euid=0`
- user command execution for normal login sessions with `auid>=1000`
- kernel module load/unload syscalls
- denied file access events with `EACCES` and `EPERM`
- host time and hostname changes

Why this shape:

- `services.journald.audit = true` makes audit events show up in journald, so
  Alloy can ship them to Loki without a separate audit log pipeline
- watched paths must exist when `auditctl -R` loads rules; keep rule set on
  stable paths that exist at boot
- this is narrow on purpose; it captures high-value host mutations without
  turning `auditd` into noise machine

Still not in live rule set:

- service-specific path watches for generated paths that may not exist at boot

If this grows later, keep same rule:

- prefer syscall rules or stable boot-time paths
- do not add watches for late-created or conditionally absent paths unless rule
  loading is handled another way

### Prometheus

Minimum scrape set:

```yaml
scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets:
          - 127.0.0.1:9090

  - job_name: node
    static_configs:
      - targets:
          - 127.0.0.1:9100

  - job_name: systemd
    static_configs:
      - targets:
          - 127.0.0.1:9558

  - job_name: traefik
    static_configs:
      - targets:
          - 127.0.0.1:8082

  - job_name: crowdsec
    static_configs:
      - targets:
          - 127.0.0.1:6060

  - job_name: cadvisor
    static_configs:
      - targets:
          - 127.0.0.1:8085

  - job_name: alloy
    static_configs:
      - targets:
          - 127.0.0.1:12345

  - job_name: loki
    static_configs:
      - targets:
          - 127.0.0.1:3100
```

Initial alert groups should cover:

- host down
- disk pressure
- memory pressure
- failed systemd units
- Traefik down
- high Traefik `5xx` rate
- high Traefik `4xx` rate
- CrowdSec down
- `cadvisor` down
- container restart spikes

### Alloy And Loki

Alloy should collect:

- Docker logs
- journald logs
- Traefik access log file
- CrowdSec logs
- audit logs via journald

Use split ingestion:

- Traefik runtime logs from Docker + `journald`
- Traefik access logs from the bind-mounted JSON access log file
- audit logs from `auditd` through journald into Loki

Label streams so Grafana queries stay simple:

- `source="docker"`
- `source="journald"`
- `source="traefik"`
- `host="albaldah"`
- `unit="crowdsec.service"` when present from journald

## Routing Model

Use subdomains, not path prefixes.

Reason:

- each UI works naturally at `/`
- fewer base-path rewrites
- simpler Traefik rules
- easier future Authentik middleware attachment

Planned routes:

- `grafana.int.djoolz.de` -> Grafana
- `prometheus.int.djoolz.de` -> Prometheus
- `loki.int.djoolz.de` -> Loki
- `alerts.int.djoolz.de` -> Alertmanager

Tailscale-only means:

- no public internet exposure for these routes
- restrict at Traefik router level and/or host firewall level to Tailscale path
- keep metrics endpoints and admin APIs off public interfaces
- during dev, all UIs can stay exposed on Tailscale
- after dev, reduce surface to Grafana only unless a stronger need remains

Authentiк later:

- add as middleware on the Traefik routers
- prefer this over long-lived shared `htpasswd` / basic-auth secrets once the
  initial dev-time exposure phase ends
- keep only Grafana's local admin secret as break-glass after Authentik is in
  front
- no need to redesign Prometheus, Loki, Grafana, or Alertmanager storage/layout

## Tests

### Static Checks

- validate Traefik config after metrics changes
- validate monitoring compose config
- validate Prometheus config and rule files
- validate Alloy config syntax
- validate repo-managed Docker baseline includes `journald` log driver

### Reachability

- `127.0.0.1:8082` serves Traefik metrics locally
- Traefik metrics are not reachable from public interfaces
- CrowdSec metrics are only reachable on intended local/private path
- `grafana.int.djoolz.de`
- `prometheus.int.djoolz.de`
- `loki.int.djoolz.de`
- `alerts.int.djoolz.de`
  all route through Traefik from Tailscale path
- those same routes are blocked or unreachable from public path

### Metrics And Logs

- Prometheus sees healthy targets for node, systemd, Traefik, CrowdSec, `cadvisor`, Alloy, Loki
- Loki receives Docker logs
- Loki receives journald logs
- Loki receives Traefik runtime logs through Docker/journald
- Loki receives Traefik access events from the JSON access log file
- Loki receives audit events through journald
- Grafana dashboards show Traefik traffic/error data
- Grafana dashboards show CrowdSec activity data
- Grafana dashboards show container CPU, memory, filesystem, and restart data from `cadvisor`

### Alerts

- force-test `TraefikDown`
- force-test `CrowdSecDown`
- force-test `cadvisor` target loss
- stop or break one scrape target to verify Alertmanager flow
- verify at least one Loki log alert and one Prometheus metric alert end to end

### Audit Queries

Initial Loki audit queries should assume journald ingestion:

```logql
{source="journald"} |= "audit"
```

If journald labels are clean enough:

```logql
{unit="auditd.service"}
```

### Runtime Helpers

- add one repo-side validation helper for expected monitoring invariants
- add one host-side smoke helper for:
  - `docker info --format '{{.LoggingDriver}}'`
  - `journalctl CONTAINER_NAME=traefik`
  - expected local scrape endpoints

## Assumptions

- `int.djoolz.de` is internal-only over Tailscale/private path
- all four UIs should get first-class routes now
- all four UIs are dev-time routes and should be reduced later
- Authentik is deferred, not rejected
- node exporter and systemd exporter are acceptable host additions if missing
- Docker hosts using the shared rootful Docker module should share the `journald`
  logging baseline
- real container metrics are in scope, so `cadvisor` is part of the first stack
- Alertmanager mail delivery will start as a placeholder config and be completed
  once SMTP details are provided
- audit logs should go to Loki through journald first, not through a separate
  audit shipping path
- Traefik and CrowdSec ownership stays in their current repos/modules
