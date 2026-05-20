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

Implemented first-line hardening in:

- `modules/nixos/services/fingerprint-06cb-009a.nix`

Change:

- Added bounded retry policy for `open-fprintd-resume.service`:
  - `Restart=on-failure`
  - `RestartSec=2s`
  - `StartLimitIntervalSec=60`
  - `StartLimitBurst=5`

## General Mitigation Outline

If failures continue after this change:

1. Disable USB autosuspend for `06cb:009a` via targeted udev rule.
2. Add explicit post-resume reinit ordering (delayed service restart/re-probe flow).
3. Add USB unbind/rebind recovery for the device before daemon restart.
4. Replace custom stack with upstream `services.fprintd` once `06cb:009a` is supported in `libfprint`.
