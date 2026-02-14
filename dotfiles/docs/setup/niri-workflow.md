# Niri Workflow

## Philosophy
- Spatial memory beats dynamic layout behavior.
- Stable placement makes workflows predictable.
- Complexity increases only after the previous tier is stable.

## Workspace model (semantic workspaces)
Named workspaces remain even when empty:

1:dev
2:research
3:comms
4:media
5:scratch

## Column semantics
- Left: reference
- Center: focus
- Right: helpers

You scroll horizontally instead of rearranging.

## Tiers

### Tier 0 - Foundation
- Basic niri config
- Keybinds
- Gaps / stable layout
- No automation

Goal: learn native workflow.

### Tier 0.5 - Predictability layer
- Window rules route apps to named workspaces.
- Example: browser -> 2:research

This is the first layer that makes behavior deterministic.

### Tier 1 - Desktop shell
- Waybar (top bar)
- Dock (Waybar at first)
- Mako notifications
- Wallpaper

UI stays quiet and reliable.

### Tier 2 - Zero-friction persistence
- Add nirinit for session persistence.
- Workspace names and outputs restored.

### Tier 2.5 - Deterministic restore
- Launch mappings for known apps.
- Skip list for transient apps.

### Tier 3 - QoL extras
- Clipboard history
- Lock screen
- Idle
- Optional animated wallpaper or eww dock

Only after the workflow is stable.
