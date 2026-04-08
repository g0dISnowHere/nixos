# Mirach Notes

## Greeter Suspend

`mirach` disables GDM greeter auto-suspend in
[power.nix](./power.nix).

Reason: this machine is a homelab host first. The GNOME login screen should not
suspend the host just because nobody logged in locally.

## Home Assistant VM Privileges

`mirach` runs the Home Assistant libvirt guest as `homeassistant`.

The guest should rely on libvirt's built-in domain autostart for startup.
`libvirt-guests` is still useful on host shutdown, but it should use ACPI
guest shutdown rather than managed save:

- `virtualisation.libvirtd.onBoot = "ignore"` to avoid duplicating libvirt
  autostart behavior
- `virtualisation.libvirtd.onShutdown = "shutdown"` to avoid creating
  managed-save images during host reboot

Using `onShutdown = "suspend"` on this host proved unreliable because the
saved-state restore path failed for `homeassistant` and left the VM offline
after reboot.

## Home Assistant Console Devices

`homeassistant` currently uses a headless libvirt definition for reliability.

The previous SPICE graphics setup caused libvirt autostart failures during host
boot with errors from the SPICE server initialization path. Manual starts after
boot could still work, but boot-time autostart was unreliable.

If that behavior returns, inspect the inactive domain definition first:

```bash
virsh -c qemu:///system dumpxml --inactive homeassistant
```

For this VM, prefer no SPICE graphics, no SPICE audio backend, and no
`spicevmc` redirection devices unless there is a specific need for an
interactive graphical console.

The host currently keeps `virtualisation.libvirtd.qemu.runAsRoot = true;` in
[libvirtd.nix](./libvirtd.nix). That setting is intentional for now.

Why it is still needed:

- the VM disk image lives at
  `/home/djoolz/Documents/02_homeassistant/haos_ova-16.0.qcow2`
- `/home/djoolz` is not traversable by the unprivileged libvirt QEMU user
- the VM NVRAM file under `/var/lib/libvirt/qemu/nvram/` is owned by `root`

If `runAsRoot` is removed without moving the VM storage and fixing ownership,
the guest will likely fail to start at boot because QEMU will not be able to
read the disk image or update NVRAM.

To remove the elevated-privileges taint cleanly:

1. move the VM disk into a libvirt-managed path such as
   `/var/lib/libvirt/images/`
2. make sure the NVRAM file is writable by the libvirt QEMU runtime user
3. rebuild with `runAsRoot = false;`
4. verify that `virsh -c qemu:///system dominfo homeassistant` still shows the
   guest starting correctly

This is separate from the `host-passthrough` CPU taint. Changing `runAsRoot`
does not affect the CPU passthrough warning.
