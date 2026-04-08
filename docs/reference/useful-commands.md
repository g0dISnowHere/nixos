# Useful Commands

This is a quick-reference document. Keep it short, current, and optimized for
lookup rather than explanation.

## Rebuild Error Output

```bash
sudo nixos-rebuild switch &>nixos-switch.log || (cat nixos-switch.log | grep --color error && exit 1)
```

```bash
sudo nixos-rebuild switch &>nixos-switch.log || (echo "NixOS rebuild failed with the following error:" && cat nixos-switch.log | grep --color error && exit 1)
```

## Keep Upgrade Logs

```bash
sudo nixos-rebuild switch --flake .# 2>&1 | tee nixos-switch.log || { grep --color error nixos-switch.log && exit 1; }
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

## Check D-Bus Activation Files

```bash
find /nix/store -path "*/share/dbus-1/services/*kdeconnect*" 2>/dev/null
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
virsh -c qemu:///system list --all
```

Show the current state and autostart flag for a domain:

```bash
virsh -c qemu:///system dominfo homeassistant
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
virsh -c qemu:///system dumpxml homeassistant
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

## Apply The Declarative `djoolz` Password

```bash
sudo nixos-rebuild switch --flake .#centauri
```

## Restart Noctalia

```bash
systemctl --user restart noctalia-shell
```

## Build `albaldah` Locally

```bash
nix build .#nixosConfigurations.albaldah.config.system.build.toplevel
```

## Install `albaldah` With `nixos-anywhere`

```bash
nix build .#nixosConfigurations.albaldah.config.system.build.toplevel && \
nix run github:nix-community/nixos-anywhere -- \
  --build-on local \
  --flake .#albaldah \
  --target-host root@YOUR_SERVER_IP
```

## Test `albaldah` Install With `nixos-anywhere`

```bash
nix build .#nixosConfigurations.albaldah.config.system.build.toplevel && \
nix run github:nix-community/nixos-anywhere -- \
  --flake .#albaldah \
  --vm-test
```
