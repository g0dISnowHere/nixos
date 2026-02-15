## Overview

This plan migrates an existing Niri-based desktop setup into a structured, versioned repo without changing behavior first, then progressively adds window rules, startup management, session restore, and health checks. It is organized into phases that keep changes incremental and reversible, with clear acceptance criteria to confirm a stable, predictable workflow.

## Detailed implementation plan with checkboxes

### Phase 0 — Foundations

* [x] Create/choose repo location (recommended: `~/dotfiles`)
* [x] Decide deployment method

  * [x] Symlink-based deploy (start here)
  * [x] Home Manager deploy (optional later)
* [x] Freeze semantic workspace map (don’t change later)

  * [x] `1:dev`
  * [x] `2:research`
  * [x] `3:comms`
  * [x] `4:media`
  * [x] `5:scratch`
  * [x] `6:engineering`

---

### Phase 1 — Repo skeleton

* [x] Create folder structure:

  * [x] `docs/`
  * [x] `docs/setup/`
  * [x] `docs/decisions/` (optional but recommended)
  * [x] `state/`
  * [x] `modules/`
  * [x] `modules/compositor/niri/`
  * [x] `modules/ui/waybar/`
  * [x] `modules/ui/mako/`
  * [x] `modules/launcher/fuzzel/`
  * [x] `scripts/`
  * [x] `health/`
  * [x] `health/checks/`
* [x] Add “intent” docs:

  * [x] `README_FOR_AI.md` (generic maintainer rules)
  * [x] `docs/setup/niri-workflow.md` (workflow + tiers)
  * [x] `state/workspace-map.md` (semantic map)
  * [x] `state/app-rules.md` (apps → workspace plan)

---

### Phase 2 — Import dotfiles into modules (no behavior changes)

* [ ] Inventory current live configs:

  * [ ] `~/.config/niri/config.kdl`
  * [ ] `~/.config/waybar/*`
  * [ ] `~/.config/mako/config`
  * [ ] launcher config (if any)
* [ ] Copy them into repo (don’t symlink yet):

  * [x] `modules/compositor/niri/config.kdl`
  * [x] `modules/ui/waybar/top.jsonc`
  * [x] `modules/ui/waybar/dock.jsonc`
  * [x] `modules/ui/waybar/style.css`
  * [x] `modules/ui/mako/config`
  * [x] `modules/launcher/fuzzel/*` (if present)
* [ ] Add tier headers to each config file:

  * [x] Tier 0 baseline present
  * [x] Tier 0.5 rules section present (commented)
  * [x] Tier 1 shell/autostarts present (commented)
  * [x] Tier 2 persistence present (commented)
  * [x] Tier 3 extras present (commented)

---

### Phase 3 — Deployment scripts (symlink-based)

* [x] Write `scripts/link.sh` (idempotent)

  * [x] Creates `~/.config` subdirs if missing
  * [x] Symlinks repo configs into `~/.config`
* [x] Write `scripts/unlink.sh`

  * [ ] Removes only symlinks created by `link.sh`
* [x] Run `scripts/link.sh`
* [x] Verify links:

  * [x] `readlink ~/.config/niri/config.kdl` points into repo
  * [x] `readlink ~/.config/waybar/top.jsonc` points into repo
  * [x] `readlink ~/.config/mako/config` points into repo
  * [x] `readlink ~/.config/noctalia` points into repo
* [ ] Confirm nothing changed behaviorally yet

---

### Phase 4 — Predictability layer (Tier 0.5 window rules)

* [x] Add ONE window rule (commented at first)

  * [x] Browser → `2:research`
* [x] Determine actual `app-id` for your browser

  * [ ] Native package?
  * [ ] Flatpak? (IDs often become `org.*`)
* [x] Enable only that one rule
* [ ] Validate:

  * [x] Browser opens in `2:research` consistently
* [ ] Add rules gradually (1/day max):

  * [ ] IDE → `1:dev`
  * [ ] Terminal (optional) → `1:dev`
  * [ ] Slack/Discord → `3:comms`
  * [ ] Spotify/music → `4:media`
* [ ] Add float rules for “junk” windows:

  * [ ] `pavucontrol` floats
  * [ ] bluetooth manager floats
  * [ ] settings dialogs float

---

### Phase 5 — Desktop shell (Tier 1) without startup conflicts

* [x] Choose ONE startup method:

  * [x] Systemd user services (recommended)
  * [ ] `spawn-at-startup` in niri
* [x] Implement top bar:

  * [x] Waybar top config with modules-left stats
  * [x] modules-center workspace indicator
  * [x] modules-right connectivity/system icons
* [x] Implement dock (simple first):

  * [x] Waybar `wlr/taskbar` dock bottom
* [x] Notifications:

  * [x] Mako config + start method selected
* [ ] Verify no duplicates:

  * [ ] Waybar started exactly once
  * [ ] Mako started exactly once

---

### Phase 6 — Zero-friction restore (Tier 2 + 2.5)

* [x] Add session persistence tool (Tier 2)

  * [x] Install `nirinit`
  * [x] Start via systemd user service OR niri spawn (not both)
* [x] Enable autosave/restore only
* [ ] Validate after relog/reboot:

  * [ ] Workspaces come back
  * [ ] Core windows reappear where expected (as supported)
  * [ ] No duplicated panels or notifiers
* [ ] Tier 2.5: add deterministic launch mappings (one at a time)

  * [ ] Browser mapping
  * [ ] IDE mapping
  * [ ] Comms mapping
* [ ] Add ignore list for transient windows

  * [ ] Audio control
  * [ ] calculators / one-off tools
  * [ ] settings dialogs

---

### Phase 7 — Self-healing health system (“doctor”)

* [x] Create `health/doctor.sh`

  * [x] Runs every script in `health/checks/`
  * [x] Prints PASS/WARN output
* [x] Implement checks:

  * [x] `check-symlinks.sh` (broken symlinks under `~/.config`)
  * [x] `check-appids.sh` (expected app IDs vs current niri windows)
  * [x] `check-duplicate-startup.sh` (systemd vs niri spawn conflicts)
  * [ ] `check-deprecated-options.sh` (optional, later)
* [x] Add `scripts/doctor.sh` wrapper
* [ ] Add shell alias (optional):

  * [ ] `dotdoctor`

---

### Phase 8 — Codex operationalization

* [x] Ensure `README_FOR_AI.md` includes:

  * [x] preserve tier structure
  * [x] new features commented out
  * [x] minimal diffs
  * [x] run `scripts/doctor.sh` before edits
* [x] Add `docs/codex-bootstrap.md` with a copy/paste prompt
* [ ] Verify Codex behavior:

  * [ ] Codex reads docs first
  * [ ] Codex doesn’t refactor away tier comments
  * [ ] Codex suggests changes as opt-in blocks

---

### Phase 9 — Rollout and rollback strategy

* [ ] Create branches per milestone:

  * [ ] `tier0-baseline`
  * [ ] `tier0.5-routing`
  * [ ] `tier1-shell`
  * [ ] `tier2-persistence`
  * [ ] `health-doctor`
* [ ] Verify rollback path:

  * [ ] `git checkout <branch>`
  * [ ] re-run `scripts/link.sh`
  * [ ] or `scripts/unlink.sh` to revert to local configs

---

## Acceptance criteria (definition of “done”)

* [ ] **Predictable app placement:** core apps always open in their semantic workspace
* [ ] **Stable workflow:** horizontal spatial memory becomes reliable
* [ ] **Restore works:** reboot/relog returns you to the same working set (as supported)
* [ ] **No startup conflicts:** bars/notifications start once, always
* [ ] **Self-healing warnings:** doctor flags broken links, ID drift, duplicate startups before breakage

---

## First Codex task (recommended starting point)

* [x] Create repo skeleton + docs (`README_FOR_AI.md`, `docs/setup/niri-workflow.md`, `state/*`)
* [ ] Implement `scripts/link.sh` and `scripts/unlink.sh`
* [ ] Import existing configs into `modules/…` unchanged
* [ ] Add tier headers and keep Tier 0.5+ commented out
