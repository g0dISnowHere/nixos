# Trackpad/TrackPoint investigation log

## Summary

- The **touchpad** works: it is the Elan Touchpad (I2C device `0-0015`), shows up as `/dev/input/event8`, and responds to libinput even after we disabled acceleration (`services.libinput` is handling it).
- The **TrackPoint** never appears as a separate `TPPS/2`/TrackPoint device—`libinput list-devices` and `libinput debug-events` only report the Elan pointer, `journalctl` shows the `trackpoint.service` triggering an `udevadm trigger --attr-match=name="TPPS/2 IBM TrackPoint"`, and there is no motion/button event when the stick is moved.
- Kernel logs show the Elan SMBus driver initializing the touchpad (`elan_i2c`), but it does not expose an additional PS/2 device for the TrackPoint and the firmware updater path refuses to run (`unexpected iap version 0x00`). The pointing stick appears to be fused into the touchpad controller.
- Suggested next steps: toggle the BIOS stick enablement if present, and try adding `boot.kernelParams = [ "i8042.nomux=1" "i8042.reset" ];` (with optional `psmouse.elantech_smbus=0`) in `configuration.nix`, rebuild, reboot, and recheck `libinput debug-events` to see if a TPPS/2 device surfaces.