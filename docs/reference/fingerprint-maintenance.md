# Fingerprint Maintenance

Quick checklist for the `centauri` fingerprint sensor (`06cb:009a`).

## Current Repo Wiring
- Local wrapper package:
  - `modules/nixos/services/fingerprint-06cb-009a-python-validity.nix`
- Local service wiring:
  - `modules/nixos/services/fingerprint-06cb-009a.nix`
- External flake input:
  - `nixos-06cb-009a-fingerprint-sensor`

## When To Check This
- after `nix flake update`
- after moving the repo to a new NixOS release
- when `nix eval .#nixosConfigurations.centauri.config.system.build.toplevel` fails
- when fingerprint login or `sudo` stops working

## Check Upstream Support

If `06cb:009a` appears here, re-evaluate whether the custom stack is still needed:

```bash
curl -fsSL https://fprint.freedesktop.org/supported-devices.html | rg '06cb:009a' | tail -n 20
```

Official list:
- <https://fprint.freedesktop.org/supported-devices.html>

## Check External Flake Branch

See whether the external flake has a branch matching the repo's target NixOS release:

```bash
rg -n 'nixos-06cb-009a-fingerprint-sensor|url = ' flake.nix flake.lock | tail -n 20
```

Project:
- <https://github.com/ahbnr/nixos-06cb-009a-fingerprint-sensor>

## Update `python-validity`

The local wrapper currently pins:
- `version`
- GitHub `rev`
- `sha256`

File:
- `modules/nixos/services/fingerprint-06cb-009a-python-validity.nix`

Typical update flow:

1. Change `version`.
2. Keep `rev = version;` if upstream tag naming still matches.
3. Temporarily set:

```nix
sha256 = lib.fakeSha256;
```

4. Run:

```bash
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel | tail -n 20
```

5. Replace `sha256` with the hash Nix prints.
6. Re-run eval.

## Factory Reset On NixOS

The upstream README uses `/usr/share/python-validity/playground/factory-reset.py`, but the Nix package here does not ship that helper script. Use the packaged module entry point instead:

```bash
sudo systemctl stop python3-validity
sudo validity-sensors-firmware
sudo python3 -c 'from validitysensor.init import open as validity_open; from validitysensor.sensor import factory_reset; validity_open(); factory_reset()'
sudo systemctl start python3-validity
```

If the reset succeeds, the command may exit with an exception after rebooting the sensor. That is expected.

## Validate After Any Change

```bash
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel | tail -n 20
sudo nixos-rebuild switch --flake .#centauri
sudo systemctl status python3-validity | tail -n 20
fprintd-verify | tail -n 20
sudo -v
```

Also test:
- swaylock unlock
- fresh GDM login
- a polkit prompt
- suspend/resume once to confirm `open-fprintd-suspend` and `open-fprintd-resume` still recover the sensor

## Likely Failure Point

If eval breaks after a `nixpkgs` update, the most likely local fix point is:

- `modules/nixos/services/fingerprint-06cb-009a-python-validity.nix`

Reason:
- this wrapper carries compatibility glue for current Python packaging in `nixpkgs`
- upstream `python-validity` packaging may lag behind

If the sensor stops working after suspend, check the `open-fprintd-suspend`, `open-fprintd-resume`, `python3-validity-suspend`, and `python3-validity-resume` units first.

`python3-validity` is configured to restart aggressively on exit (`Restart=always`, `RestartSec=1s`, `StartLimitIntervalSec=0`) so a transient USB loss does not leave fingerprint auth dead until the next manual restart. It is also stopped explicitly before sleep and restarted explicitly after resume.

## Resume Reliability Hardening

Resume handling is hardened in three layers:

1. USB autosuspend is disabled for `06cb:009a`:
   - udev rule forces `power/control=on`
2. `open-fprintd-resume.service` retries to survive transient resume-time USB races:
   - `Restart=on-failure`
   - `RestartSec=2s`
   - `StartLimitIntervalSec=60`
   - `StartLimitBurst=5`
3. `python3-validity` is managed explicitly around sleep:
   - `python3-validity-suspend.service` stops it before sleep
   - `python3-validity-resume.service` restarts it after `open-fprintd-resume.service`
   - steady-state daemon restart policy is `Restart=always`, `RestartSec=1s`, `StartLimitIntervalSec=0`

This is wired in:

- `modules/nixos/services/fingerprint-06cb-009a.nix`

Validate after deploy:

```bash
systemctl status open-fprintd-resume.service | tail -n 20
systemctl status python3-validity.service | tail -n 20
journalctl -b -u open-fprintd-resume.service --no-pager | tail -n 40
journalctl -b -u python3-validity-resume.service --no-pager | tail -n 40
cat /sys/bus/usb/devices/1-9/power/control
```

Expected steady state:

- `/sys/bus/usb/devices/1-9/power/control` = `on`
- `python3-validity-resume.service` exists and runs after `open-fprintd-resume.service`

## Larger Mitigations (If Failures Persist)

If retries are not enough, apply mitigations in this order:

1. Add USB unbind/rebind recovery for the sensor before restarting the fingerprint daemons.
2. Add custom post-resume recovery ordering with additional delays if the current explicit stop/restart flow is still not enough.
3. Move back to standard `services.fprintd` once `06cb:009a` is upstream-supported by `libfprint`.
