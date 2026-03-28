# Gnome Keyring Findings (Centauri)

## Summary
- The running keyring daemon is `gnome-keyring-daemon` from `/nix/store/1hph4z6s270mqswf32whng9hijvbp7i5-gnome-keyring-48.0/bin/gnome-keyring-daemon`.
- The Secret Service login collection is present and **unlocked** (Locked = false).
- The `login` keyring file was created on **February 14, 2026 at 18:54:28 +0100** (`~/.local/share/keyrings/login.keyring`).

## Likely Cause of Auto-Login Issues
- Auto-unlock requires PAM hooks for the *login service actually used* (TTY login, or a greeter like GDM).
- On this system we did **not** see an active display manager service, and `/etc/pam.d` had no gnome-keyring entries, which explains missing auto-unlock when switching from GNOME to niri.

## Changes Applied in This Repo
- File: `modules/nixos/desktop/niri.nix`
  - Enabled PAM auto-unlock for TTY logins:
    - `security.pam.services.login.enableGnomeKeyring = true;`
  - Enabled PAM auto-unlock for GDM logins:
    - `security.pam.services.gdm-password.enableGnomeKeyring = true;`
  - Enabled the GDM greeter:
    - `services.displayManager.gdm.enable = true;`
    - `services.displayManager.gdm.wayland = true;`

## Notes
- If you switch to a different greeter (e.g., greetd/ly/sddm), add the corresponding PAM service with `enableGnomeKeyring = true`.
