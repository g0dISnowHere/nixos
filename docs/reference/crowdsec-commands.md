# CrowdSec Commands

Quick lookup for CrowdSec maintenance, health checks, debugging, reenrollment,
and credential recovery on `albaldah`.

Use with:

- [docs/vps/crowdsec-on-albaldah.md](../vps/crowdsec-on-albaldah.md)
- [docs/vps/crowdsec-auth-domains.md](../vps/crowdsec-auth-domains.md)

## Core Health

```bash
scripts/crowdsec-verify.sh
sudo systemctl status crowdsec crowdsec-firewall-bouncer crowdsec-console-enroll | tail -n 40
sudo journalctl -u crowdsec -u crowdsec-firewall-bouncer -u crowdsec-console-enroll -b -n 100 --no-pager | tail -n 80
sudo cscli version
sudo cscli console status | tail -n 20
sudo cscli capi status | tail -n 20
sudo cscli bouncers list | tail -n 20
sudo cscli metrics | tail -n 20
```

## Listener And Traffic Checks

```bash
sudo ss -ltnp | rg '8080|7422' | tail -n 20
curl -I http://127.0.0.1:8080/health | tail -n 20
curl -sS -o /dev/null -w '%{http_code}\n' -X POST -d '{}' http://127.0.0.1:7422/ | tail -n 20
docker exec traefik wget -S -O- http://host.docker.internal:8080/health | tail -n 20
docker exec traefik wget -S -O- --post-data '{}' http://host.docker.internal:7422/ | tail -n 20
```

## Firewall And Docker Path

```bash
sudo systemctl status crowdsec-firewall-bouncer | tail -n 30
sudo journalctl -u crowdsec-firewall-bouncer -b -n 80 --no-pager | tail -n 60
sudo iptables -S INPUT | tail -n 20
sudo iptables -S DOCKER-USER | tail -n 20
sudo ip6tables -S INPUT | tail -n 20
sudo ip6tables -S DOCKER-USER | tail -n 20
```

Expected shape:

- `DOCKER-USER` should jump to `CROWDSEC_CHAIN`
- firewall bouncer logs should not warn that Docker traffic is not configured

## Hub Drift And Update Checks

This repo currently keeps CrowdSec hub auto-update enabled. Use these commands
first when the daemon suddenly breaks after previously working.

```bash
sudo systemctl status crowdsec-update-hub.timer | tail -n 20
sudo systemctl list-timers | rg crowdsec | tail -n 20
sudo journalctl -u crowdsec-update-hub.service -b -n 80 --no-pager | tail -n 60
sudo cscli scenarios list | tail -n 40
sudo cscli collections list | tail -n 40
```

Known failure class:

- newer hub content can outrun the installed engine
- on this host that showed up as `http-technology-probing` using `LookupFile`
  while the older engine could not parse it

## Rebuild And Recheck

```bash
sudo nixos-rebuild switch --flake .#albaldah
sudo systemctl status crowdsec crowdsec-firewall-bouncer crowdsec-console-enroll | tail -n 40
sudo journalctl -u crowdsec -u crowdsec-firewall-bouncer -u crowdsec-console-enroll -b -n 100 --no-pager | tail -n 80
```

## Log Source Checks

```bash
docker info --format '{{.LoggingDriver}}' | tail -n 20
sudo ls -l /var/log/traefik/access.json | tail -n 20
sudo head -n 5 /var/log/traefik/access.json | tail -n 20
sudo journalctl -u crowdsec -b | rg -i 'Appsec listening|Appsec Runner|Shutting down Appsec server' | tail -n 20
```

## Detection Checks

```bash
for i in {1..10}; do
  curl -sk -o /dev/null https://djoolz.de/.env
done
sudo cscli metrics | tail -n 20
sudo cscli alerts list | tail -n 20
sudo cscli alerts list -a | tail -n 20
sudo cscli decisions list | tail -n 20
```

Interpretation:

- `alerts list` shows active alerts only
- `alerts list -a` is better for history while debugging
- parser and scenario counters in `metrics` are first proof of activity

## Console Reenroll

Use when Console token changed or Console state needs to be replaced.

Repo side:

```bash
sops secrets/services/crowdsec/console-enrollment-token.yaml
scripts/secrets sync-policy --check | tail -n 20
sudo nixos-rebuild switch --flake .#albaldah
```

Host side:

```bash
sudo sed -i '/^enroll_key:/d' /var/lib/crowdsec/console.yaml
sudo systemctl start crowdsec-console-enroll
sudo systemctl status crowdsec-console-enroll | tail -n 20
sudo journalctl -u crowdsec-console-enroll -b -n 40 --no-pager | tail -n 40
sudo cscli console status | tail -n 20
```

Important:

- use a fresh Console enrollment token
- if the secret file changed, keep normal SOPS workflow intact before deploy

## CAPI Runtime Credential Repair

Use when `cscli capi status` fails or `/var/lib/crowdsec/online_api_credentials.yaml`
needs rotation.

```bash
sudo systemctl stop crowdsec crowdsec-firewall-bouncer
sudo rm -f /var/lib/crowdsec/online_api_credentials.yaml
sudo systemctl start crowdsec
sudo systemctl start crowdsec-capi-register
sudo systemctl restart crowdsec-firewall-bouncer-register crowdsec-firewall-bouncer
sudo cscli capi status | tail -n 20
sudo systemctl status crowdsec crowdsec-firewall-bouncer | tail -n 30
```

## Local API Credential Repair

Use when `crowdsec.service` fails with local watcher auth errors such as
`authenticate watcher ... API error: Forbidden`.

```bash
sudo systemctl stop crowdsec crowdsec-firewall-bouncer
sudo rm -f /var/lib/crowdsec/local_api_credentials.yaml
sudo systemctl start crowdsec
sudo systemctl restart crowdsec-firewall-bouncer-register crowdsec-firewall-bouncer
sudo systemctl status crowdsec crowdsec-firewall-bouncer | tail -n 30
sudo journalctl -u crowdsec -b -n 80 --no-pager | tail -n 60
```

If startup also complains that online creds are missing, regenerate those too
with the CAPI repair flow above.

## Incompatible Hub Scenario Recovery

Use when CrowdSec dies while loading a scenario after a hub update.

```bash
sudo systemctl stop crowdsec crowdsec-update-hub.timer crowdsec-update-hub.service
sudo systemctl disable crowdsec-update-hub.timer
sudo systemctl mask crowdsec-update-hub.service
sudo cscli scenarios remove crowdsecurity/http-technology-probing
sudo find /etc/crowdsec -name '*http-technology-probing*' -ls | tail -n 20
sudo systemctl restart crowdsec
sudo systemctl status crowdsec | tail -n 30
sudo journalctl -u crowdsec -b -n 80 --no-pager | tail -n 60
```

If the file still exists after removal:

```bash
sudo rm -f /etc/crowdsec/scenarios/http-technology-probing.yaml
sudo systemctl restart crowdsec
```

## Credential Exposure Response

If Console token or CAPI runtime credentials were pasted into chat or otherwise
exposed:

```bash
sudo rm -f /var/lib/crowdsec/online_api_credentials.yaml
sudo systemctl start crowdsec-capi-register
sudo systemctl restart crowdsec-firewall-bouncer-register crowdsec-firewall-bouncer
```

Then rotate the Console enrollment token in
`secrets/services/crowdsec/console-enrollment-token.yaml`, rebuild, and run the
Console reenroll flow above.
