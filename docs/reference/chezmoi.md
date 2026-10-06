# Native application settings with chezmoi

NixOS/Home Manager install chezmoi and SOPS. Selected native files have a separate
mutable source at `~/.local/share/chezmoi`; they are not links into the Nix store.
Centauri is the conflict authority. Each destination has one owner.

## Ownership and scope

All five hosts declare chezmoi. Shared targets are btop, Herdr, OpenCode and GitHub
CLI. Centauri, Mirach and Karaka additionally receive Zellij and native Orca,
PrusaSlicer and FreeCAD preference-pack libraries. Albaldah and Alhena ignore
those GUI trees. Installing a library does not install the corresponding app:
Mirach currently has no PrusaSlicer or FreeCAD Flatpak installation.

The previous Home Manager Herdr and Zellij file owners were removed. Existing
Home Manager/platform settings remain with their existing owners; there is no
second generic linker, custom profile merger or unconditional pull-and-apply service.

## Automatic synchronization

The dedicated source is published to the private
[`g0dISnowHere/dotfiles`](https://github.com/g0dISnowHere/dotfiles) repository,
branch `main`. This remote is separate from the NixOS repository.

Centauri is the **only automatic publisher**: native app changes to managed plain
files are captured with chezmoi, checked and committed to this source. Other hosts
only receive revisions. Edits on receiving hosts remain local and block an apply;
reconcile them deliberately with Centauri rather than expecting multi-writer merges.
Credential templates are never re-added or published as rendered files.

Home Manager installs `chezmoi-sync.service` and a five-minute user timer. The
shared NixOS user enables lingering so the timer does not require a desktop login.
Git authentication uses GitHub CLI and the existing SOPS `djoolz-gh-hosts` payload
through a temporary private configuration; no additional token is stored in Git.
The worker serializes runs, refuses dirty source or unexpected remotes/revisions,
uses fast-forward-only updates, and checks local destination changes before apply.
It avoids applying files that an active app may rewrite. Skipped work is retried
by the next timer run; inspect the journal rather than assuming every tick applies.

```bash
systemctl --user status chezmoi-sync.timer
systemctl --user start chezmoi-sync.service
journalctl --user -u chezmoi-sync.service -n 40 --no-pager
git -C ~/.local/share/chezmoi log -5 --oneline
```

## Capture and apply

1. Close an app before applying files it rewrites on exit.
2. Capture an explicitly selected, managed **plain** file:

   ```bash
   chezmoi re-add "$HOME/.config/btop/btop.conf"
   chezmoi diff "$HOME/.config/btop/btop.conf"
   ```

3. Review changes in the separate source and reconcile conflicts with Centauri.
   Its publisher commits and pushes safe plain-file changes automatically; other
   hosts must not publish independent histories.
4. Provision runtime secrets before applying:

   ```bash
   chezmoi --no-tty apply
   chezmoi verify --exclude scripts
   ```

Do not bulk-enroll configuration directories. `chezmoi add` on a rendered
credential-bearing destination can replace a safe template with plaintext.
`re-add` skips templates; UI-written changes to credentialed presets must be
reconciled into the encrypted SOPS payload, not captured into ordinary source.
Avoid unrestricted `chezmoi diff` or template rendering in logs: their output can
include decrypted credentials. Inspect plain targets individually.

Printer preset selection and FreeCAD pack selection remain host-local. Native
libraries synchronize portable assets, not mixed device/history/window profiles.
FreeCAD exposes the `Centauri` pack in its native Preferences pack manager; use
its Apply action deliberately. Do not capture `user.cfg` as a whole.

## Credentials

The existing `users.djoolz` SOPS policy supplies recipients. No second age or
recipient inventory was introduced.

| Encrypted artifact | Runtime payload | Hosts |
| --- | --- | --- |
| `secrets/users/djoolz/chezmoi.yaml` | `djoolz-gh-hosts`, `djoolz-opencode-auth` | all five |
| `secrets/users/djoolz/orca-machine-presets.yaml` | four `djoolz-orca-*` files | Centauri, Mirach, Karaka |
| `secrets/users/djoolz/prusa-machine-presets.yaml` | `djoolz-prusa-presets` JSON map | Centauri, Mirach, Karaka |

sops-nix files are owned by `djoolz:users`, mode `0400`. Fourteen private chezmoi
templates read those runtime files; rendered credential files are mode `0600`.
Nix evaluation and store-built configuration contain ciphertext and runtime paths,
not decrypted payloads. The separate source and offline archive contain templates,
not their rendered credential values.

GitHub's native `hosts.yml` can contain only account metadata while its token is
in the desktop keyring. Copying metadata alone does not migrate authentication.
The migration exported Centauri's native credential privately, enrolled it using
`gh auth login --with-token --insecure-storage` in an isolated config directory,
and encrypted the resulting native file with SOPS. Scratch plaintext was removed.
To verify the deployed file rather than an environment token, use:

```bash
env -u GH_TOKEN -u GITHUB_TOKEN -u GH_ENTERPRISE_TOKEN \
  -u GITHUB_ENTERPRISE_TOKEN gh api --hostname github.com user --jq .login
```

Centauri's native OpenCode `auth.json` contains an OpenRouter API-key credential.
It is encrypted intact and rendered at `~/.local/share/opencode/auth.json`.
OAuth refresh/session credentials are not included; a new provider or auth type
needs a portability review before updating this native payload.

Do not print `gh auth token`, secret files, or decrypted SOPS documents into logs.
Use the [existing secrets workflow](../secrets-workflows.md) for updates, then
redeploy sops-nix before applying chezmoi. SSH identities, paired-device private
keys and browser/session credentials are not copied between machines.

## Backup and recovery

Before migration, four reachable hosts received private backups under
`~/.local/state/chezmoi-migration/20261004T175420Z`. Centauri additionally received
a full relevant sandbox backup at `20261004T181737Z-sandboxes`. Backups record
original file modes and symlink destinations, hash resolved bytes before/after
archiving, extract the archive into a fresh recovery directory, and verify the
recovered bytes. Checksums alone are not the recovery proof.

The native `run_before_00-verified-backup.sh.tmpl` performs the same actual
extraction check **before every apply**, records absent targets and original
parent-directory modes, and refuses mutation when a required runtime secret is
unavailable. Each apply uses a fresh timestamped `*-preapply.XXXXXX` directory,
even when two applies occur within one second.

The worker first applies only `00-verified-backup.sh`, then applies selected
destinations in a separate command. `--parent-dirs` creates missing native
directories; `--recursive=false --exclude scripts` prevents unrelated file
selection and a second backup. Running the script in the same parent-directory
apply can execute it after files have changed. Manual targeted applies:

```bash
chezmoi --no-tty apply -- "$HOME/00-verified-backup.sh"
chezmoi --no-tty apply --parent-dirs --recursive=false --exclude scripts -- "$HOME/.config/gh/config.yml"
```

Exclude scripts from verification because this recurring before-script is always
pending; `chezmoi verify --exclude scripts` checks the managed native files.

The initial rollout's backups are:

| Host | Backup directory suffix |
| --- | --- |
| Albaldah | `20261004T192826Z-preapply` |
| Centauri | `20261004T192825Z-preapply` |
| Mirach | `20261004T193025Z-preapply` |
| Alhena | `20261004T193025Z-preapply` |
| Karaka | `20261005T214655Z-preapply.IrddWg` |

Karaka's listed archive is a post-migration snapshot, not an original-file
backup. During its initial enrollment, a parent-directory apply changed its four
existing targets before the backup script ran: btop, GitHub config/hosts and
Zellij. Their original hashes were recorded, but exact original-byte recovery
copies were not found. The worker now uses the separate backup command above.

For recovery, stop the relevant app, verify the archive's recorded checksum,
extract privately, and verify recovered file checksums before replacing targets.
Use the mode/link manifest to restore ownership boundaries. Resolved-byte archives
preserve content even if an old Nix-store symlink target has been garbage-collected;
restoring that old symlink itself requires its target to remain available.

## Offline handoff: Alhena

Karaka became reachable during final verification. Its NixOS configuration,
runtime secrets, native source and timer are deployed. Native verification of
all 40 targets and the receiver service passed. Its initial backup-ordering
failure is recorded in the recovery section; do not use that archive to claim
recovery of its four pre-migration files.

Alhena remains offline; its updated deployment and runtime verification are
explicitly deferred. All five NixOS configurations declare the worker, native
source URL and role-specific runtime secrets. Deploy Alhena once reachable:

```bash
nix run .#deploy-rs -- .#alhena
```

The worker enrolls an absent or uncommitted initial source without deleting its
old contents, then receives the private remote. Committed source histories,
unexpected remotes and existing local destination/login changes are not silently
replaced. Close apps that rewrite managed files before retrying a skipped apply.
Karaka requires seven runtime secrets; Alhena requires the two shared secrets.
Verify `chezmoi --version`, timer/service journal, `chezmoi verify --exclude scripts`, native GitHub
authentication and applicable app checks after deployment. A built closure is
not a completed offline rollout.

A private source recovery capsule, excluding Git metadata and rendered credentials,
is also retained at:

`~/.local/state/chezmoi-migration/fleet-source-auto-20261005T194537Z.tar`

SHA256: `3e2f9c3593ebacca1c2e9ee8030325a622484fe65fbd299b7d721801b73a51ab`.

It contains the initial published revision; use the remote for later changes.

Alhena's initial online rollout was deployed/applied and its native chezmoi version
was verified. Its first activation hit WSL's protected binfmt registry;
`wsl.interop.register = false` leaves ownership with WSL while preserving the
Windows handler. The repaired activation and `cmd.exe /c ver` passed.
During the final credential pass Alhena went offline: SSH timed out and Tailscale
reported `Online=false`, last seen `2026-10-05T17:28:51Z`; it remains offline during
synchronization setup. Its updated deployment is deferred under the authorized
offline rule. Recheck native GitHub authentication and OpenCode auth after apply;
the initial installed generation does not contain the final credential updates.

## Inventory dispositions

| Application / area | Disposition | Native scope or reason |
| --- | --- | --- |
| btop | migrated | native config; isolated TUI capture/apply/relaunch, graceful exit |
| Herdr | migrated | native TOML; native `config check`, private preference capture/apply; existing server left untouched |
| OpenCode | migrated | native JSON permissions and SOPS-backed OpenRouter API-key auth; native reader and private permission capture/apply; no model calls |
| GitHub CLI | migrated | native config and SOPS-rendered credential file; native keyring export required |
| Zellij | migrated | native KDL; isolated native session; clipboard command resolved without reading clipboard |
| OrcaSlicer | migrated | 9 process + 2 filament presets, 4 SOPS-backed machine presets; native GUI recognized custom presets and consumed a captured outer-wall width |
| PrusaSlicer | migrated | 6 print + 2 filament presets, 6 printer + 2 physical-printer SOPS-backed presets; official entrypoint/session-bus GUI recognized presets and valid model; native CLI consumed a captured filament temperature |
| FreeCAD | migrated | native typed `Centauri` preference pack; native UI Apply changed units/navigation while preserving an unrelated sentinel; native Save as New captured a console-color pack and its UI Apply consumed the restored pack |
| VS Code | already synchronized | active native Sync log verified settings, keybindings, snippets, tasks, MCP, extensions, prompts, profiles and global state |
| Browsers | excluded | explicit browser-profile exclusion; no second owner |
| Blender | excluded | user-approved legacy-profile exclusion; 5.2 compatibility of 4.4/4.5/5.0 profiles not established; backups preserved |
| GTK, Niri, Noctalia, Nautilus, Flatseal, Refine, GNOME extensions | excluded | existing declarative/platform or host-local ownership; no whole desktop/device/dconf-profile copy |
| Audacity | excluded | mixed device/temp/window settings; no authored effect presets/macros found |
| Inkscape | excluded | mixed preferences; custom keys/palettes/templates/symbols empty |
| LibreOffice | excluded | mixed registry; authored templates/macros/autocorrect absent; dictionary header only |
| LibreCAD | excluded | mixed geometry profile; no authored standalone assets; newer Exchange UI unavailable in installed version |
| KiCad | excluded | only legacy 9.0 profile found with 10.0.6 installed; no current custom theme/hotkey library |
| GIMP | excluded | actual 3.2 config asset directories empty; tiny stock gradient/shared print shortcut; mixed tool-option state not captured |
| EasyEffects, VLC, OBS | excluded | no authored preset library identified; device/layout/history or generated defaults stay local |
| Wireshark | excluded | interface/extcap and credentials mixed; native profile assets empty |
| DBeaver | excluded | default workspace; no authored connections or SQL settings library |
| MQTT Explorer | excluded | mixed connection/credential JSON; no native portable export identified |
| Moonlight, Solaar | excluded | paired-host private keys/certificates or hardware serial/device state |
| nnn | excluded | bookmark/mount/session state stays local; plugin directory empty |
| Cava | excluded | no config file; eight residual shaders/themes exactly match [upstream factory Git blobs](https://github.com/karlstav/cava/tree/master/output), not authored settings |
| Carla, Surge XT, Webcamoid, mslicer, OpenSCAD | excluded | no eligible standalone settings library established; mixed backend/device state not copied |
| Planify | excluded | task database/cache, not portable settings; actual ID `io.github.alainm23.planify` |
| Warehouse, FlatSweep, Bottles | excluded | historical backup archives, first-launch flag or downloaded runner/cache state; no authored library identified |
| RustDesk | excluded | peer/device/credential state; no portable standalone settings library identified |
| Bitwarden, Signal, Thunderbird, Spotify | excluded | vault/message/account/session state not copied; native preference synchronization not asserted |
| htop, procps | excluded | absent configuration or empty directory |

Native GUI proofs used private cloned profiles, Xvfb and isolated session buses;
no printing, slicing, credentialed device connection or model/provider request was
performed. Preset availability is not equivalent to effective whole-profile sync.
Runtime receipt files and private evidence images belong under
`~/.local/state/chezmoi-migration/`, not in Git.
