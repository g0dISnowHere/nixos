# Niri Desktop ARD (Architecture Requirements Document)

## 1. Architecture Goals
- Provide a composable Wayland desktop shell around niri.
- Preserve spatial workflow and stable window sizing.
- Keep components replaceable and loosely coupled.
- Enforce deterministic startup and restore paths.

## 2. System Context
- Base: Linux + Wayland protocol.
- Compositor: niri (scrollable tiling, per-monitor workspaces).
- Shell components are external clients communicating via Wayland and DBus.

## 3. Components and Responsibilities
### Core
- Niri: window management, input handling, rendering, workspace logic.

### Shell
- Waybar: top panel (stats, workspaces, status icons).
- Dock: Waybar taskbar (tier 1) or eww (tier 3 optional).
- Mako: notifications.
- Fuzzel: app launcher.
- Swaybg: wallpaper.
- Polkit agent: auth prompts.

### Optional QoL
- Clipboard history (e.g., cliphist + launcher integration).
- Swaylock + swayidle for locking and idle handling.

## 4. Configuration Sources
- Niri: `dotfiles/modules/compositor/niri/config.kdl` (symlinked to `~/.config/niri/config.kdl`).
- Waybar: `dotfiles/modules/ui/waybar/` (top + dock configs + CSS).
- Mako: `dotfiles/modules/ui/notifications/mako.conf`.
- Launcher: `dotfiles/modules/ui/launcher/` (fuzzel config).
- Workflow intent: `dotfiles/docs/setup/niri-workflow.md` and `dotfiles/state/`.

## 5. Startup and Initialization
- Single startup source for each component (avoid duplicates).
- Startup order (recommended):
  1. Niri starts session.
  2. Waybar (top), then Waybar dock (if used).
  3. Mako notification daemon.
  4. Wallpaper via swaybg.
  5. Optional: clipboard/idle/lock services.

## 6. Data and Control Flows
- Input -> niri -> window focus/move/overview.
- Waybar modules -> DBus/NetworkManager/UPower/PipeWire.
- Notifications -> Mako via DBus.
- Launcher -> spawns apps -> niri manages placement.

## 7. Workspace Semantics
- Named semantic workspaces remain stable (1:dev, 2:research, etc.).
- Window rules enforce deterministic placement.
- Columns have semantic meaning: left reference, center focus, right helpers.

## 8. Tiered Architecture
- Tier 0: niri core + keybindings + stable layout.
- Tier 0.5: workspace routing rules.
- Tier 1: shell components (Waybar, Mako, Wallpaper).
- Tier 2: session persistence with deterministic restore order.
- Tier 2.5: explicit launch mappings + skip lists.
- Tier 3: QoL extras (clipboard, idle/lock, optional eww dock).

## 9. Reliability and Determinism
- Avoid dual autostart paths (niri vs systemd user).
- Prefer explicit startup definitions.
- Add checks for duplicate startup and app-id drift.

## 10. Security Considerations
- Polkit agent must be present for privilege prompts.
- Lock screen required before enabling idle handling.
- No secrets stored in configs; use proper secret management.

## 11. Performance Considerations
- Minimize background animations.
- Waybar CSS should be lightweight.
- Avoid heavy widget systems until tier 3.

## 12. Observability and Health Checks
- Use `dotfiles/scripts/doctor.sh` to validate:
  - App-id drift.
  - Duplicate autostarts.
  - Broken symlinks.
- Track state snapshots if persistence tier is enabled.

## 13. Migration and Extensibility
- Components can be swapped: Waybar -> eww, Mako -> alternative.
- Must preserve workspace semantics and tier structure.
- New features are introduced commented-out by default.

## 14. Risks
- App-id changes break routing rules (mitigate with checks).
- Duplicate autostarts cause inconsistent state (mitigate with checks).
- Over-customization can erode predictability (enforce tier rules).
