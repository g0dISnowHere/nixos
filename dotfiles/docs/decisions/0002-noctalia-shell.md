# Decision 0002 — Noctalia as shell UI

Date: 2026-02-14

## Decision
- Use Noctalia as the desktop shell (bar + control center) for niri.
- Disable Waybar (Noctalia replaces it).
- Keep niri window rules as the single source of truth for app routing.

## Notes
- Noctalia is enabled via NixOS module and bound to `niri.service`.
- Mako remains the notification daemon.
