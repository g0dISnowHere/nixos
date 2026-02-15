# Niri Desktop PRD

## 1. Purpose
Define the product requirements for a modular, predictable niri-based desktop that delivers a macOS-like shell (top bar + dock + clean notifications) while preserving niri's scrollable tiling workflow and spatial memory model.

## 2. Problem Statement
Traditional desktop environments are heavy and opaque. Tiling compositors often sacrifice predictability or visual polish. The goal is a minimalist, composable niri setup that provides essential desktop UX components without breaking spatial workflows.

## 3. Goals
- Stable spatial workflow with scrollable tiling and predictable placement.
- Modular shell components (panel, dock, notifications, launcher).
- Quiet, low-noise UI that prioritizes focus.
- Deterministic startup and restore (later tiers).
- Clear tiered evolution without destabilizing behavior.

## 4. Non-Goals
- Full DE integration (no monolithic settings app).
- Large, animated widgets as the default baseline.
- Dynamic reflowing layouts that change window sizes unexpectedly.
- Replacing niri's core workflow with alt-tab centric navigation.

## 5. Target Users
- Power users who value spatial memory and keyboard-first workflows.
- Users wanting a macOS-like bar/dock without GNOME/KDE.
- Nix/NixOS users who prefer declarative configuration.

## 6. User Experience Principles
- Predictability over novelty.
- Stable window sizes and workspace semantics.
- Minimal visual noise; UI should fade into the background.
- Incremental complexity via tiers; new features are opt-in.

## 7. Functional Requirements
### Core (Tier 0)
- FR-0.1: Enable niri as the Wayland compositor.
- FR-0.2: Provide core keybindings for focus, move, close, overview.
- FR-0.3: Ensure stable gaps and borders for predictable layout.

### Predictability Layer (Tier 0.5)
- FR-0.5.1: Workspace naming and semantic mapping (e.g., 1:dev, 2:research).
- FR-0.5.2: Window rules route apps to their semantic workspaces.

### Desktop Shell (Tier 1)
- FR-1.1: Top bar showing system stats left, workspaces center, status icons right.
- FR-1.2: Dock-like launcher (Waybar taskbar initially).
- FR-1.3: Notifications via a minimal daemon.
- FR-1.4: Wallpaper support.

### Persistence (Tier 2)
- FR-2.1: Session persistence and workspace restore.
- FR-2.2: Restoration order is deterministic.

### Deterministic Restore (Tier 2.5)
- FR-2.5.1: Explicit app-id to launch command mapping.
- FR-2.5.2: Exclude transient windows from restore.

### QoL Extras (Tier 3)
- FR-3.1: Clipboard history.
- FR-3.2: Lock screen and idle handling.
- FR-3.3: Optional auto-hide dock or animated dock (eww).

## 8. Non-Functional Requirements
- NFR-1: Configurations remain readable and auditable.
- NFR-2: Startup is deterministic; no duplicate autostarts.
- NFR-3: Minimal CPU/GPU overhead for idle UI components.
- NFR-4: Modularity: components can be swapped (Waybar vs eww) without cascading changes.
- NFR-5: Changes should be additive, not destructive.

## 9. Constraints
- Niri is compositor-only; all shell features must be external components.
- Configuration is file-based (KDL and supporting configs).
- Nix/NixOS environment favors declarative configs and explicit imports.
- Preserve tier boundaries and do not auto-enable advanced tiers.

## 10. Success Metrics
- User can navigate spatially with minimal window rearrangement.
- Core workflow remains stable across reboots.
- Shell components load reliably with no duplicates.
- Workspace routing behaves deterministically.

## 11. Dependencies
- Niri compositor
- Waybar (top bar + initial dock)
- Mako (notifications)
- Fuzzel (launcher)
- Swaybg (wallpaper)
- Optional: eww (advanced dock)

## 12. Acceptance Criteria
- Core tiers (0, 0.5, 1) work without manual intervention after login.
- Top bar provides stats left, workspaces center, status right.
- Dock provides icon-based app switching.
- Workspace routing reflects semantic model consistently.
- No regressions in spatial workflow or window stability.
