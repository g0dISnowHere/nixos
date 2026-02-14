# Decision 0003 — Track Noctalia config in dotfiles

Date: 2026-02-14

## Decision
- Track Noctalia config in `dotfiles/modules/ui/noctalia/`.
- Symlink `~/.config/noctalia` to the dotfiles copy via `dotfiles/scripts/link.sh`.

## Notes
- This keeps Noctalia settings, plugins, and themes under version control.
- Use `dotfiles/scripts/link.sh` after Noctalia GUI changes to persist updates.
