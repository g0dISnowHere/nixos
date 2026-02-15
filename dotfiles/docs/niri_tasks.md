# Niri Desktop Tasks

## Scope
Implement the niri workflow in staged tiers, ensuring predictability and minimal UI noise.

## Phase 0: Foundation (Tier 0)
- [ ] Verify niri is enabled and launching cleanly.
- [ ] Confirm base keybinds: focus left/right, move left/right, overview, close.
- [ ] Set stable gaps/borders.
- [ ] Ensure config lives in `dotfiles/modules/compositor/niri/config.kdl` and is symlinked.
- [ ] Run `dotfiles/scripts/doctor.sh` and resolve any warnings.

## Phase 0.5: Predictability Layer
- [ ] Define semantic workspaces (1:dev, 2:research, 3:comms, 4:media, 5:scratch, 6:engineering).
- [ ] Add window rules to route key apps to those workspaces.
- [ ] Validate app-ids with `niri msg windows` during active sessions.
- [ ] Confirm routing works on multi-monitor setups without overlap.

## Phase 1: Desktop Shell
- [ ] Configure Waybar top panel with stats left, workspaces center, status right.
- [ ] Add dock (Waybar taskbar) and ensure it launches once.
- [ ] Configure Mako notifications (quiet defaults).
- [ ] Add wallpaper via swaybg.
- [ ] Confirm no duplicate autostarts (Waybar/Mako).

## Phase 2: Zero-Friction Persistence
- [ ] Add nirinit (or equivalent) session persistence.
- [ ] Ensure workspace names and outputs restore deterministically.
- [ ] Verify restore order preserves spatial memory.
- [ ] Document the restore sequence in `dotfiles/docs/setup/niri-workflow.md` if needed.

## Phase 2.5: Deterministic Restore
- [ ] Add explicit app-id -> launch command mapping.
- [ ] Create skip list for transient windows (dialogs, file pickers, etc.).
- [ ] Validate that restored apps land on correct workspaces.

## Phase 3: QoL Extras
- [ ] Add clipboard history integration.
- [ ] Add lock screen + idle handling.
- [ ] Optional: auto-hide or animated dock (eww).
- [ ] Optional: launcher enhancements (cliphist, calculator, emoji).

## Validation Checklist (Run Per Phase)
- [ ] `dotfiles/scripts/doctor.sh` passes.
- [ ] No duplicate autostarts detected.
- [ ] Workspace routing is consistent.
- [ ] UI remains quiet and stable.
