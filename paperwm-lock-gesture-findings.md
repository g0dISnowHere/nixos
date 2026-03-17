# PaperWM Touchpad Gesture Findings

## Question

Why do PaperWM touchpad gestures work after login, but stop working after the GNOME session is locked and then unlocked?

## Short Answer

This does not look like a NixOS or Home Manager configuration problem.

It looks like a live GNOME session state problem triggered by lock/unlock:

- PaperWM gesture handling works correctly after login.
- Locking and unlocking the GNOME session changes gesture handling state.
- After unlock, GNOME's native swipe tracker appears to receive touchpad gesture events again.
- PaperWM does not fully reclaim control of those gesture hooks until the user logs out and back in.

## What The Repo Config Shows

Relevant config in `modules/home/dconf/dconf.nix`:

- `org/gnome/shell.disable-user-extensions = false`
- `paperwm@paperwm.github.com` is in `enabled-extensions`
- `org/gnome/shell/extensions/paperwm.gesture-enabled = true`
- `org/gnome/shell/extensions/paperwm.gesture-horizontal-fingers = 3`
- screen locking is enabled via `org/gnome/desktop/screensaver.lock-enabled = true`

This means the declarative config is explicitly enabling PaperWM and its gestures.

## What The Installed PaperWM Extension Does

The active PaperWM extension is installed locally at:

- `~/.local/share/gnome-shell/extensions/paperwm@paperwm.github.com`

Its metadata reports:

- UUID: `paperwm@paperwm.github.com`
- version-name: `49.0.1`
- supported GNOME Shell versions include `49`

PaperWM handles gestures by:

- listening for `TOUCHPAD_SWIPE` events on `global.stage`
- disabling GNOME's built-in swipe trackers

Relevant local source files:

- `~/.local/share/gnome-shell/extensions/paperwm@paperwm.github.com/gestures.js`
- `~/.local/share/gnome-shell/extensions/paperwm@paperwm.github.com/patches.js`

Notable behavior from the source:

- PaperWM resets swipe trackers on extension enable
- it also resets them when the overview is hidden
- there is no obvious dedicated lock/unlock or screen shield reinitialization path

There is also an explicit comment in `extension.js` that lock/disable can leave PaperWM in a "breakable state".

## Runtime Findings

Observed behavior from testing:

- PaperWM touchpad gestures work after login.
- After lock/unlock, gestures stop working.
- Restarting the PaperWM extension does **not** restore gestures.
- Using the GNOME extension manager also does **not** restore gestures.
- Logging out and logging back in **does** restore gestures.

## Journal Evidence

The user journal after unlock shows GNOME's own swipe tracker code handling touchpad gestures:

- `resource:///org/gnome/shell/ui/swipeTracker.js`
- `_updateTouchpadGesture`
- `_endTouchpadGesture`

That is important because PaperWM normally tries to take over this area by disabling GNOME's built-in swipe trackers.

This suggests that after unlock:

- GNOME's native gesture handling is active again
- PaperWM is no longer fully controlling the gesture path
- restarting just the extension is not enough to recover the session state

## Interpretation

Most likely explanation:

1. On login, PaperWM correctly hooks gesture handling.
2. Lock/unlock causes GNOME Shell to recreate or reactivate internal gesture/swipe tracking.
3. PaperWM does not fully reassert its gesture takeover afterward.
4. The session remains in a partially stale state until the full GNOME session is restarted by logging out.

## What This Likely Is Not

This is likely **not**:

- a touchpad hardware issue
- a missing PaperWM enablement setting
- a broken Home Manager dconf declaration
- a permanently broken PaperWM install

## Most Likely Root Cause

Most likely:

- a GNOME Shell 49 / Mutter 49 session-state interaction
- or a PaperWM `49.0.1` compatibility bug around screen lock / unlock

## Practical Conclusion

Current best conclusion:

PaperWM gesture support is initialized correctly at login, but lock/unlock leaves GNOME Shell and PaperWM in an inconsistent gesture-handling state. A full logout/login resets that state; reloading the extension does not.

That points to a runtime compatibility bug between GNOME Shell's unlock path and PaperWM's gesture takeover logic, rather than a declarative Nix configuration issue.
