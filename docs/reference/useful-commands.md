# Useful Commands

This is a quick-reference document. Keep it short, current, and optimized for
lookup rather than explanation.

## Rebuild Error Output

```bash
sudo nixos-rebuild switch &>nixos-switch.log || (tail -n 20 nixos-switch.log | grep --color error && exit 1)
```

```bash
sudo nixos-rebuild switch &>nixos-switch.log || (echo "NixOS rebuild failed with the following error:" && tail -n 20 nixos-switch.log | grep --color error && exit 1)
```

## Keep Upgrade Logs

```bash
sudo nixos-rebuild switch --flake .# 2>&1 | tee nixos-switch.log || { tail -n 20 nixos-switch.log | grep --color error && exit 1; }
```

## Roll Back

```bash
sudo nixos-rebuild switch --flake .# --rollback
```

## List System Generations

```bash
sudo nixos-rebuild list-generations
```

## Update `dconf.nix`

```bash
dconf dump / | dconf2nix > modules/home/dconf/dconf.nix
```

## List Dev Templates

```bash
nix flake show path:/home/djoolz/Documents/01_config/mine | tail -n 20
```

## Create Project From Dev Template

```bash
nix flake new --template path:/home/djoolz/Documents/01_config/mine#rust ./my-rust-project | tail -n 20
```

## Initialize Current Directory From Dev Template

```bash
nix flake init --template path:/home/djoolz/Documents/01_config/mine#python | tail -n 20
```

## Smoke-Test A Local Dev Template

```bash
nix flake new --template .#empty /tmp/dev-template-test | tail -n 20
```

## Check D-Bus Activation Files

```bash
find /nix/store -path "*/share/dbus-1/services/*kdeconnect*" 2>/dev/null | tail -n 20
```

## See Recent System Updates

```bash
nix profile diff-closures --profile /nix/var/nix/profiles/system | tail -n 50
```

## Log Out

```bash
loginctl terminate-user djoolz
```

## Common `virsh` Commands

List all system libvirt domains:

```bash
virsh -c qemu:///system list --all | tail -n 20
```

Show the current state and autostart flag for a domain:

```bash
virsh -c qemu:///system dominfo homeassistant | tail -n 20
```

Start or stop a domain:

```bash
virsh -c qemu:///system start homeassistant
virsh -c qemu:///system shutdown homeassistant
```

Force a fresh boot and ignore a managed-save image:

```bash
virsh -c qemu:///system start homeassistant --force-boot
```

Remove a stale managed-save image:

```bash
virsh -c qemu:///system managedsave-remove homeassistant
```

Enable or disable libvirt autostart for a domain:

```bash
virsh -c qemu:///system autostart homeassistant
virsh -c qemu:///system autostart --disable homeassistant
```

Inspect the live domain XML:

```bash
virsh -c qemu:///system dumpxml homeassistant | tail -n 20
```

Rename an inactive domain:

```bash
virsh -c qemu:///system domrename old-name new-name
```

## Rotate The Declarative `djoolz` Password

```bash
EDITOR=nano sops secrets/users/djoolz/password.yaml
```

The file stores `hashedPassword`, not a plaintext password hash.

## Basic SOPS Commands

Edit a secret file:

```bash
EDITOR=nano sops secrets/services/example/example.yaml
```

Print decrypted contents:

```bash
sops decrypt secrets/services/example/example.yaml
```

Refresh recipient metadata for one file:

```bash
sops updatekeys secrets/services/example/example.yaml
```

## Apply The Declarative `djoolz` Password

```bash
sudo nixos-rebuild switch --flake .#centauri
```

## Restart Noctalia

```bash
systemctl --user restart noctalia-shell
```

## Fingerprint: Check Driver Service

```bash
sudo systemctl status python3-validity | tail -n 20
```

## Fingerprint: Enroll

```bash
fprintd-enroll
```

## Fingerprint: Verify

```bash
fprintd-verify
```

## Fingerprint: Download Sensor Firmware

```bash
sudo validity-sensors-firmware
```

## Fingerprint: Check Recent Logs

```bash
sudo journalctl -u python3-validity -b --no-pager | tail -n 20
```

## Fingerprint: Check If `06cb:009a` Is Upstream-Supported

```bash
curl -fsSL https://fprint.freedesktop.org/supported-devices.html | rg '06cb:009a' | tail -n 20
```

## Fingerprint: Check Flake Input Version

```bash
rg -n 'nixos-06cb-009a-fingerprint-sensor|url = ' flake.nix flake.lock | tail -n 20
```

## Build `albaldah` Locally

```bash
nix build .#nixosConfigurations.albaldah.config.system.build.toplevel | tail -n 20
```

## Install `albaldah` With `nixos-anywhere`

```bash
nix build .#nixosConfigurations.albaldah.config.system.build.toplevel && \
nix run github:nix-community/nixos-anywhere -- \
  --build-on local \
  --flake .#albaldah \
  --target-host root@YOUR_SERVER_IP | tail -n 20
```

## Test `albaldah` Install With `nixos-anywhere`

```bash
nix build .#nixosConfigurations.albaldah.config.system.build.toplevel && \
nix run github:nix-community/nixos-anywhere -- \
  --flake .#albaldah \
  --vm-test | tail -n 20
```

## Check CrowdSec On `albaldah`

```bash
ssh albaldah 'sudo systemctl status crowdsec crowdsec-firewall-bouncer; sudo cscli metrics | tail -n 20'
```

## Check CrowdSec Listeners On `albaldah`

```bash
ssh albaldah "ss -ltnp | rg '8080|7422' | tail -n 20"
```

## Watch CrowdSec Logs On `albaldah`

```bash
ssh albaldah 'sudo journalctl -u crowdsec -f | tail -n 20'
```

## Show CrowdSec Alerts On `albaldah`

```bash
ssh albaldah 'sudo cscli alerts list -a -n 20 | tail -n 20'
```

## Show CrowdSec Decisions On `albaldah`

```bash
ssh albaldah 'sudo cscli decisions list -n 20 | tail -n 20'
```

## Test CrowdSec Traefik Log Readability On `albaldah`

```bash
ssh albaldah "docker info --format '{{.LoggingDriver}}' | tail -n 20 && sudo ls -l /var/log/traefik/access.log | tail -n 20 && sudo head -n 5 /var/log/traefik/access.log | tail -n 20"
```

## Test CrowdSec AppSec Reachability From Traefik On `albaldah`

```bash
ssh albaldah "docker exec traefik wget -S -O- http://host.docker.internal:8080/health | tail -n 20 && docker exec traefik wget -S -O- --post-data '{}' http://host.docker.internal:7422/ | tail -n 20"
```
