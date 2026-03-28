# Decision 0003 — Track Noctalia config in dotfiles

Date: 2026-02-14

## Decision
- Track Noctalia config in `dotfiles/modules/ui/noctalia/`.
- Link `~/.config/noctalia` to the dotfiles copy via Home Manager.

## Notes
- This keeps Noctalia settings, plugins, and themes under version control.
- Use `home-manager switch` to refresh the managed link after Noctalia GUI
  changes.
