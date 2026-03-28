# Decision 0003 — Track Noctalia config in dotfiles

Date: 2026-02-14

## Decision
- Track Noctalia config in `dotfiles/modules/ui/noctalia/`.
- Keep `~/.config/noctalia` as a normal writable directory.
- Link the repo-managed Noctalia files and directories into it via Home Manager.

## Notes
- This keeps Noctalia settings, plugins, and themes under version control.
- The directory itself must stay writable because Noctalia installs plugins and
  writes runtime state under `~/.config/noctalia/`.
- Use `home-manager switch` to refresh the managed link after Noctalia GUI
  changes.
