# Centauri Fingerprint Resume Failures: Root Cause Snapshot

Date: 2026-05-19
Host: `centauri`
Sensor: `06cb:009a` (`Synaptics Metallica MIS Touch Fingerprint Reader`)

## Summary

Recent failures are primarily resume-time USB instability, not a permanently dead fingerprint daemon.

The recurring chain is:

1. Kernel resume hiccup on xHCI (`USBSTS 0x401`, reinit/reset activity).
2. Fingerprint USB device (`usb 1-9`, `06cb:009a`) disconnect/reset/re-enumeration.
3. `open-fprintd-resume.service` fails in `resume.py` (`No such device`, occasionally protocol parse errors).
4. Later auth attempts fail in `python3-validity` with `USBTimeoutError` and `CancelledException`.

## Evidence Highlights

- `usb 1-9` maps to the fingerprint reader (`06cb:009a`) in kernel logs.
- Resume window includes:
  - `xHC error in resume, USBSTS 0x401, Reinit`
  - `usb 1-9: USB disconnect`
  - re-enumeration of `idVendor=06cb, idProduct=009a`
- `open-fprintd-resume.service` failures include:
  - `usb.core.USBError: [Errno 19] No such device (it may have been disconnected)`
  - `Exception: Dont know how to handle message type 15`
  - `Exception: Failed: 0315`
- `python3-validity` verify failures include:
  - `usb.core.USBTimeoutError: [Errno 110] Operation timed out`
  - `validitysensor.usb.CancelledException`

## What Was Changed

Implemented hardening in:

- `modules/nixos/services/fingerprint-06cb-009a.nix`

Changes:

1. Added bounded retry policy for `open-fprintd-resume.service`:
   - `Restart=on-failure`
   - `RestartSec=2s`
   - `StartLimitIntervalSec=60`
   - `StartLimitBurst=5`
2. Disabled USB autosuspend for `06cb:009a` via udev (`power/control=on`).
3. Added explicit sleep orchestration for `python3-validity`:
   - `python3-validity-suspend.service` stops it before sleep
   - `python3-validity-resume.service` restarts it after `open-fprintd-resume.service`
   - steady-state daemon restart policy is `Restart=always`, `RestartSec=1s`, `StartLimitIntervalSec=0`

## General Mitigation Outline

If failures continue after these changes:

1. Add USB unbind/rebind recovery for the device before daemon restart.
2. Add more explicit delayed post-resume reinit ordering if the sensor still races re-enumeration.
3. Replace custom stack with upstream `services.fprintd` once `06cb:009a` is supported in `libfprint`.
