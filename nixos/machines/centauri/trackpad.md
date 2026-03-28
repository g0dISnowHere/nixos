# Trackpad/TrackPoint investigation log

## Summary

- The **touchpad** works: it is the Elan Touchpad (I2C device `0-0015`), shows up as `/dev/input/event8`, and responds to libinput even after we disabled acceleration (`services.libinput` is handling it).
- The **TrackPoint** never appears as a separate `TPPS/2`/TrackPoint device—`libinput list-devices` and `libinput debug-events` only report the Elan pointer, `journalctl` shows the `trackpoint.service` triggering an `udevadm trigger --attr-match=name="TPPS/2 IBM TrackPoint"`, and there is no motion/button event when the stick is moved.
- Kernel logs show the Elan SMBus driver initializing the touchpad (`elan_i2c`), but it does not expose an additional PS/2 device for the TrackPoint and the firmware updater path refuses to run (`unexpected iap version 0x00`). The pointing stick appears to be fused into the touchpad controller.
- Suggested next steps: toggle the BIOS stick enablement if present, and try adding `boot.kernelParams = [ "i8042.nomux=1" "i8042.reset" ];` (with optional `psmouse.elantech_smbus=0`) in `configuration.nix`, rebuild, reboot, and recheck `libinput debug-events` to see if a TPPS/2 device surfaces.

## Commands and relevant output

### `sudo libinput list-devices`
Device:                  Power Button
Kernel:                  /dev/input/event3
Id:                      host:0000:0001
Group:                   1
Seat:                    seat0, default
Capabilities:            keyboard 
Tap-to-click:            n/a
Tap-and-drag:            n/a
Tap button map:          n/a
Tap drag lock:           n/a
Left-handed:             n/a
Nat.scrolling:           n/a
Middle emulation:        n/a
Calibration:             n/a
Scroll methods:          none
Scroll button:           n/a
Scroll button lock:      n/a
Click methods:           none
Clickfinger button map:  n/a
Disable-w-typing:        n/a
Disable-w-trackpointing: n/a
Accel profiles:          n/a
Rotation:                0.0
Area rectangle:          n/a

Device:                  Video Bus
Kernel:                  /dev/input/event5
Id:                      host:0000:0006
Group:                   2
Seat:                    seat0, default
Capabilities:            keyboard 
Tap-to-click:            n/a
Tap-and-drag:            n/a
Tap button map:          n/a
Tap drag lock:           n/a
Left-handed:             n/a
Nat.scrolling:           n/a
Middle emulation:        n/a
Calibration:             n/a
Scroll methods:          none
Scroll button:           n/a
Scroll button lock:      n/a
Click methods:           none
Clickfinger button map:  n/a
Disable-w-typing:        n/a
Disable-w-trackpointing: n/a
Accel profiles:          n/a
Rotation:                0.0
Area rectangle:          n/a

Device:                  Lid Switch
Kernel:                  /dev/input/event2
Id:                      host:0000:0005
Group:                   3
Seat:                    seat0, default
Capabilities:            switch
Tap-to-click:            n/a
Tap-and-drag:            n/a
Tap button map:          n/a
Tap drag lock:           n/a
Left-handed:             n/a
Nat.scrolling:           n/a
Middle emulation:        n/a
Calibration:             n/a
Scroll methods:          none
Scroll button:           n/a
Scroll button lock:      n/a
Click methods:           none
Clickfinger button map:  n/a
Disable-w-typing:        n/a
Disable-w-trackpointing: n/a
Accel profiles:          n/a
Rotation:                0.0
Area rectangle:          n/a

Device:                  Sleep Button
Kernel:                  /dev/input/event1
Id:                      host:0000:0003
Group:                   4
Seat:                    seat0, default
Capabilities:            keyboard 
Tap-to-click:            n/a
Tap-and-drag:            n/a
Tap button map:          n/a
Tap drag lock:           n/a
Left-handed:             n/a
Nat.scrolling:           n/a
Middle emulation:        n/a
Calibration:             n/a
Scroll methods:          none
Scroll button:           n/a
Scroll button lock:      n/a
Click methods:           none
Clickfinger button map:  n/a
Disable-w-typing:        n/a
Disable-w-trackpointing: n/a
Accel profiles:          n/a
Rotation:                0.0
Area rectangle:          n/a

Device:                  Logitech USB Receiver
Kernel:                  /dev/input/event6
Id:                      usb:046d:c547
Group:                   5
Seat:                    seat0, default
Capabilities:            pointer 
Tap-to-click:            n/a
Tap-and-drag:            n/a
Tap button map:          n/a
Tap drag lock:           n/a
Left-handed:             disabled
Nat.scrolling:           disabled
Middle emulation:        disabled
Calibration:             n/a
Scroll methods:          button
Scroll button:           BTN_MIDDLE
Scroll button lock:      disabled
Click methods:           none
Clickfinger button map:  n/a
Disable-w-typing:        n/a
Disable-w-trackpointing: n/a
Accel profiles:          flat *adaptive custom
Rotation:                0.0
Area rectangle:          n/a

Device:                  Logitech USB Receiver Keyboard
Kernel:                  /dev/input/event7
Id:                      usb:046d:c547
Group:                   5
Seat:                    seat0, default
Capabilities:            keyboard pointer 
Tap-to-click:            n/a
Tap-and-drag:            n/a
Tap button map:          n/a
Tap drag lock:           n/a
Left-handed:             n/a
Nat.scrolling:           disabled
Middle emulation:        n/a
Calibration:             n/a
Scroll methods:          none
Scroll button:           n/a
Scroll button lock:      n/a
Click methods:           none
Clickfinger button map:  n/a
Disable-w-typing:        n/a
Disable-w-trackpointing: n/a
Accel profiles:          n/a
Rotation:                0.0
Area rectangle:          n/a

Device:                  Elan Touchpad
Kernel:                  /dev/input/event8
Id:                      i2c:04f3:002f
Group:                   6
Seat:                    seat0, default
Size:                    98x61mm
Capabilities:            pointer gesture
Tap-to-click:            disabled
Tap-and-drag:            enabled
Tap button map:          left/right/middle
Tap drag lock:           disabled
Left-handed:             disabled
Nat.scrolling:           disabled
Middle emulation:        disabled
Calibration:             n/a
Scroll methods:          *two-finger edge 
Scroll button:           n/a
Scroll button lock:      n/a
Click methods:          *button-areas clickfinger 
Clickfinger button map:  left/right/middle
Disable-w-typing:        enabled
Disable-w-trackpointing: enabled
Accel profiles:          flat *adaptive custom
Rotation:                n/a
Area rectangle:          n/a

Device:                  AT Translated Set 2 keyboard
Kernel:                  /dev/input/event0
Id:                      serial:0001:0001
Group:                   7
Seat:                    seat0, default
Capabilities:            keyboard 
Tap-to-click:            n/a
Tap-and-drag:            n/a
Tap button map:          n/a
Tap drag lock:           n/a
Left-handed:             n/a
Nat.scrolling:           n/a
Middle emulation:        n/a
Calibration:             n/a
Scroll methods:          none
Scroll button:           n/a
Scroll button lock:      n/a
Click methods:           none
Clickfinger button map:  n/a
Disable-w-typing:        n/a
Disable-w-trackpointing: n/a
Accel profiles:          n/a
Rotation:                0.0
Area rectangle:          n/a

Device:                  ThinkPad Extra Buttons
Kernel:                  /dev/input/event4
Id:                      host:17aa:5054
Group:                   8
Seat:                    seat0, default
Capabilities:            keyboard 
Tap-to-click:            n/a
Tap-and-drag:            n/a
Tap button map:          n/a
Tap drag lock:           n/a
Left-handed:             n/a
Nat.scrolling:           n/a
Middle emulation:        n/a
Calibration:             n/a
Scroll methods:          none
Scroll button:           n/a
Scroll button lock:      n/a
Click methods:           none
Clickfinger button map:  n/a
Disable-w-typing:        n/a
Disable-w-trackpointing: n/a
Accel profiles:          n/a
Rotation:                0.0
Area rectangle:          n/a

### `lsusb`
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 001 Device 002: ID 046d:c547 Logitech, Inc. USB Receiver
Bus 001 Device 003: ID 058f:9540 Alcor Micro Corp. AU9540 Smartcard Reader
Bus 001 Device 005: ID 8087:0a2b Intel Corp. Bluetooth wireless interface
Bus 001 Device 006: ID 04f2:b604 Chicony Electronics Co., Ltd Integrated Camera (1280x720@30)
Bus 001 Device 042: ID 06cb:009a Synaptics, Inc. Metallica MIS Touch Fingerprint Reader
Bus 001 Device 043: ID 2cb7:0210 Fibocom L830-EB-00 LTE WWAN Modem
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 002 Device 002: ID 0bda:0316 Realtek Semiconductor Corp. Card Reader
Bus 002 Device 004: ID 0951:1666 Kingston Technology DataTraveler 100 G3/G4/SE9 G2/50 Key
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub

### `journalctl -k | grep -i trackpoint`
Feb 02 01:27:47 centauri systemd[1]: Starting trackpoint.service...

### `xinput list`
WARNING: running xinput against an Xwayland server. See the xinput man page for details.
⎡ Virtual core pointer                          id=2    [master pointer  (3)]
⎜   ↳ Virtual core XTEST pointer                id=4    [slave  pointer  (2)]
⎜   ↳ xwayland-pointer:16                       id=6    [slave  pointer  (2)]
⎜   ↳ xwayland-relative-pointer:16              id=7    [slave  pointer  (2)]
⎜   ↳ xwayland-pointer-gestures:16              id=8    [slave  pointer  (2)]
⎣ Virtual core keyboard                         id=3    [master keyboard (2)]
	↳ Virtual core XTEST keyboard               id=5    [slave  keyboard (3)]
	↳ xwayland-keyboard:16                      id=9    [slave  keyboard (3)]

### `systemctl status trackpoint.service`
● trackpoint.service
	 Loaded: loaded (/etc/systemd/system/trackpoint.service; enabled; preset: ignored)
	 Active: active (exited) since Mon 2026-02-02 01:27:47 CET; 1 day 20h ago
 Invocation: 8b30647b358b48089961f9897af1de9c
   Main PID: 471 (code=exited, status=0/SUCCESS)
		 IO: 484K read, 0B written
   Mem peak: 4M
		CPU: 116ms

Feb 02 01:27:47 centauri systemd[1]: Finished trackpoint.service.
Notice: journal has been rotated since unit was started, output may be incomplete.

### `journalctl -u trackpoint.service`
Okt 04 18:51:18 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Okt 04 18:51:18 centauri systemd[1]: Stopped trackpoint.service.
-- Boot b7492a4f861f443791965208ae01f79c --
Okt 04 18:51:51 centauri systemd[1]: Finished trackpoint.service.
Okt 11 14:17:25 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Okt 11 14:17:25 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 5a1ba18b9eb44b03bcb64042686384af --
Okt 14 16:11:27 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Okt 14 16:11:27 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 1339498ff7c64b1badd4e31d788fdaf4 --
Okt 16 16:57:01 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Okt 16 16:57:01 centauri systemd[1]: Stopped trackpoint.service.
-- Boot d4411c0295bc40bba8cb687e59438bd2 --
Okt 16 16:57:44 centauri systemd[1]: Finished trackpoint.service.
Okt 21 16:56:25 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Okt 21 16:56:25 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 059b044cb62548f8aeaafa15b1a35e42 --
Okt 27 17:13:21 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Okt 27 17:13:21 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 059b044cb62548f8aeaafa15b1a35e42 --
Okt 27 17:13:51 centauri systemd[1]: Finished trackpoint.service.
Nov 04 08:40:54 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Nov 04 08:40:54 centauri systemd[1]: Stopped trackpoint.service.
Nov 04 08:41:17 centauri systemd[1]: Starting trackpoint.service...
Nov 04 08:41:17 centauri systemd[1]: Finished trackpoint.service.
Nov 04 08:49:30 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Nov 04 08:49:30 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 35c8b100247e4b4ab4d9de2563c07e29 --
Nov 04 17:04:42 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Nov 04 17:04:42 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 4a0117b65fac45cbbf29f331e2a11845 --
Nov 04 17:05:13 centauri systemd[1]: Finished trackpoint.service.
Nov 05 09:22:24 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Nov 05 09:22:24 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 7a0f2cc3d86a4518baea6813c3cf65fd --
Nov 25 14:41:15 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Nov 25 14:41:15 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 2f66360b8c2f43feb577299fcc5e6d63 --
Nov 27 18:40:02 centauri systemd[1]: Finished trackpoint.service.
Nov 30 11:47:35 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Nov 30 11:47:35 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 6d13faef6c594b209b1752dbe9270f6d --
Dez 02 21:03:59 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 02 21:03:59 centauri systemd[1]: Stopped trackpoint.service.
-- Boot cbc1e87e93b242b8a9746824ba3a3c19 --
Dez 02 21:04:28 centauri systemd[1]: Finished trackpoint.service.
Dez 06 09:43:43 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 06 09:43:43 centauri systemd[1]: Stopped trackpoint.service.
Dez 06 09:43:50 centauri systemd[1]: Starting trackpoint.service...
Dez 06 09:43:50 centauri systemd[1]: Finished trackpoint.service.
Dez 06 11:38:38 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 06 11:38:38 centauri systemd[1]: Stopped trackpoint.service.
-- Boot a776f32941eb498382de80d796b61f96 --
Dez 06 11:39:24 centauri systemd[1]: Finished trackpoint.service.
Dez 13 10:46:07 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 13 10:46:07 centauri systemd[1]: Stopped trackpoint.service.
-- Boot ad64ae8f3e49479e9e5e38005a06685e --
Dez 13 10:46:38 centauri systemd[1]: Finished trackpoint.service.
Dez 14 09:10:50 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 14 09:10:50 centauri systemd[1]: Stopped trackpoint.service.
-- Boot afb9b9cca09346a2801aeddaabf6543e --
Dez 14 09:11:33 centauri systemd[1]: Finished trackpoint.service.
Dez 14 15:26:22 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 14 15:26:22 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 66f64e16ce5d4497a32006c6649f8ef2 --
Dez 17 10:43:39 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 17 10:43:39 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 66f64e16ce5d4497a32006c6649f8ef2 --
Dez 17 10:44:04 centauri systemd[1]: Starting trackpoint.service...
Dez 17 10:44:04 centauri systemd[1]: Finished trackpoint.service.
Dez 17 10:57:07 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 17 10:57:07 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 85fa48c57fd24d448c6f536216dc6cef --
Dez 21 13:58:11 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 21 13:58:11 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 9dd744cb820a43c393aae24269a8ad7d --
Dez 21 19:13:18 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 21 19:13:18 centauri systemd[1]: Stopped trackpoint.service.
-- Boot b39ba3683731469f8344f7da80308f2a --
Dez 21 19:14:12 centauri systemd[1]: Finished trackpoint.service.
Dez 22 22:54:44 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 22 22:54:44 centauri systemd[1]: Stopped trackpoint.service.
-- Boot bc5c59dca6164917a0402d5898d4607c --
Dez 22 22:55:13 centauri systemd[1]: Finished trackpoint.service.
Dez 24 16:11:35 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Dez 24 16:11:35 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 6a2da9b56b944e4c90496d6d8e1a3335 --
Dez 24 16:11:58 centauri systemd[1]: Finished trackpoint.service.
-- Boot f0c2c81d9f5f4fc7abfab2568cc84e34 --
Dez 26 18:46:32 centauri systemd[1]: Finished trackpoint.service.
Jan 05 12:16:02 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Jan 05 12:16:02 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 6af84f311fa749cfaea493128e9c58bf --
Jan 05 12:16:29 centauri systemd[1]: Finished trackpoint.service.
-- Boot 80e320e9f579480fb44370d6aff6e7ee --
Jan 12 12:07:32 centauri systemd[1]: Finished trackpoint.service.
Jan 12 14:10:57 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Jan 12 14:10:57 centauri systemd[1]: Stopped trackpoint.service.
Jan 12 14:11:22 centauri systemd[1]: Starting trackpoint.service...
Jan 12 14:11:22 centauri systemd[1]: Finished trackpoint.service.
-- Boot 4aa7796d04cc40c383f424c47ed223e3 --
Jan 19 10:03:27 centauri systemd[1]: Finished trackpoint.service.
-- Boot c56a79fcc0d949b880ef43723fcb5387 --
Jan 20 13:37:13 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Jan 20 13:37:13 centauri systemd[1]: Stopped trackpoint.service.
-- Boot 310a7bad10464ef6a1f6d8a3eb9a54ec --
Jan 20 13:37:41 centauri systemd[1]: Finished trackpoint.service.
-- Boot 128286a7c6bd48829404485ac59b17d7 --
Jan 22 13:23:37 centauri systemd[1]: Finished trackpoint.service.
Jan 22 15:27:29 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Jan 22 15:27:29 centauri systemd[1]: Stopped trackpoint.service.
-- Boot af78e9a8b5844622b0bb12a7e5773de7 --
Jan 22 15:28:04 centauri systemd[1]: Finished trackpoint.service.
-- Boot 9a4f7af9160b487ea9e0d59f33077f62 --
Jan 29 20:06:20 centauri systemd[1]: Finished trackpoint.service.
-- Boot 8ddbc291037a4441b72e96c755b0f59b --
Jan 30 17:43:33 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Jan 30 17:43:33 centauri systemd[1]: Stopped trackpoint service.
-- Boot 27f20ccb5b27455fa0c433b7f75419fe --
Feb 02 01:27:21 centauri systemd[1]: trackpoint.service: Deactivated successfully.
Feb 02 01:27:21 centauri systemd[1]: Stopped trackpoint service.
-- Boot c0017fd1b0f8403c806f608945ffb573 --
Feb 02 01:27:47 centauri systemd[1]: Finished trackpoint.service.

### `systemctl cat trackpoint.service`
[Unit]
Before=sysinit.target shutdown.target
Conflicts=shutdown.target
DefaultDependencies=false

[Service]
Environment="LOCALE_ARCHIVE=/nix/store/wz5p0m6fdzfl1nvfr13sc262przl8vfd-glibc-locales-2.40-66/lib/locale/locale-archive"
Environment="PATH=/nix/store/iiishysy5bzkjrawxl4rld1s04qj0k0c-coreutils-9.8/bin:/nix/store/6hcyzg88adcz37hn5pslwb06ck6pnq07-findutils-4.10.0/bin:/nix/store/737jwbhw8ji13x9s88z3wpp8pxaqla92-gnugrep-3.12/bin:/nix/store/rm3yhwgahfrmshmcrv6cr28x4rz7881s-gnused-4.9/bin:/nix/store/yxk9smkrispxlz2ka3gxigvmzhf0fn65-systemd-258.2/bin:/nix/store/iiishysy5bzkjrawxl4rld1s04qj0k0c-coreutils-9.8/sbin:/nix/store/6hcyzg88adcz37hn5pslwb06ck6pnq07-findutils-4.10.0/sbin:/nix/store/737jwbhw8ji13x9s88z3wpp8pxaqla92-gnugrep-3.12/sbin:/nix/store/rm3yhwgahfrmshmcrv6cr28x4rz7881s-gnused-4.9/sbin:/nix/store/yxk9smkrispxlz2ka3gxigvmzhf0fn65-systemd-258.2/sbin"
Environment="TZDIR=/nix/store/xh1ff9c9c0yv1wxrwa5gnfp092yagh7v-tzdata-2025b/share/zoneinfo"
ExecStart=/nix/store/yxk9smkrispxlz2ka3gxigvmzhf0fn65-systemd-258.2/bin/udevadm trigger --attr-match=name="TPPS/2 IBM TrackPoint"

RemainAfterExit=true
Type=oneshot

[Install]
WantedBy=sysinit.target

### `/proc/bus/input/devices` (whole file)
<the same content as above>???
