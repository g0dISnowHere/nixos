# Native application settings with chezmoi

NixOS/Home Manager install chezmoi and SOPS. Selected native files have a separate
mutable source at `~/.local/share/chezmoi`; they are not links into the Nix store.
The intended fleet topology is peer publishing and receiving for native managed
plain settings. Centauri was only a temporary migration source of truth, not the
permanent authority. Verify activation independently on each host; this policy
does not establish deployment status.

## Ownership and scope

All importing hosts receive the same managed plain-file inventory, including
ordinary desktop application settings. Secret-template destinations are selected
per declared, provisioned runtime-secret dependencies rather than by host role.
Installing a library does not install its corresponding app.

The previous Home Manager Herdr and Zellij file owners were removed. Existing
Home Manager/platform settings remain with their existing owners; there is no
second generic linker, custom profile merger or unconditional pull-and-apply service.

## Automatic synchronization

The intended policy is for each importing host to publish and receive native
managed plain-file changes through the private
[`g0dISnowHere/dotfiles`](https://github.com/g0dISnowHere/dotfiles) repository,
branch `main`. This remote is separate from the NixOS repository. Capture is
limited to explicitly managed plain files; credential templates and rendered
credential destinations are never captured.

The worker receives safe incoming updates before capture, then publishes local
changes. Fast-forward updates and disjoint edits can synchronize automatically.
When both sides edit the same target, synchronization stops and preserves both
edits for deliberate manual reconciliation; it never force-pushes or overwrites a
divergent edit.

Home Manager installs `chezmoi-sync.service` and a five-minute user timer. The
shared NixOS user enables lingering so the timer does not require a desktop login.
Git authentication uses GitHub CLI and the existing SOPS `djoolz-gh-hosts` payload
through a temporary private configuration; no additional token is stored in Git.
The worker serializes runs, requires the expected remote and `main` revisions, and
receives safe incoming updates before capture. Fast-forward and disjoint changes
can synchronize automatically; same-target collisions stop before backup or apply,
preserving both edits for manual reconciliation. A rejected push leaves committed
local data intact for a later run to reconcile. It avoids applying files that an
active app may rewrite; inspect the journal rather than assuming every timer tick
applies.

Scheduled synchronization compares and updates plain-file contents only. It does
not import native permission changes or rewrite source paths or chezmoi
attributes; existing managed source entries retain their path and attributes.

### New-host onboarding

The declared inventory is the same for every importing host; native templates
select credential targets from the runtime secrets provisioned on that host, not
from a hostname allowlist. After Home Manager activation, the existing
timer starts within one five-minute interval. It can bootstrap an absent source,
create missing target parents, and apply eligible shared files, including
ordinary desktop settings on a headless host. This is automatic timer-based
onboarding, not immediate operating-system installation; it still depends on
GitHub authentication and applications not actively rewriting the affected
settings.

During first enrollment, a native target already matching the fetched source is
not rewritten, even when its application is active. That unchanged busy target
does not block other missing settings from applying. A divergent native target
still stops onboarding before other writes or the applied-revision marker.

Only credential destinations whose declared runtime-secret dependencies are
available are selected. Undeclared optional printer credentials therefore do not
prevent plain settings from applying. Conversely, any secret declared as
provisioned through `CHEZMOI_EXPECTED_SECRETS` but missing or unreadable causes a
visible failure before writes. Removing a secret from provisioning later does
not delete a credential file that was already rendered; deprovisioning is not
destructive.

An existing same-file divergence stops synchronization and preserves both local
and incoming edits for deliberate reconciliation. Do not resolve it by deleting
the native destination or resetting the source.

### Explicit source-schema cutovers

Changes to `.chezmoidata.toml` or `.chezmoiignore` are administrator-managed
source migrations, never automatic publisher captures. Coordinate the worker and
private source schema as one fleet rollout:

1. Immediately before the administrative source cutover, stop both
   `chezmoi-sync.timer` and `chezmoi-sync.service` on every importing host, then
   verify both are inactive. Do not rely on a systemd mask as a pause: Home
   Manager may leave these user units enabled, and activation can restart them.
   If any activation or source update may restart a unit, stop both again and
   verify inactivity immediately before fast-forwarding or activating.
2. Require a clean native source tree on every host. Fetch `origin/main` and
   confirm it can fast-forward; reconcile divergent edits deliberately. Update
   schema metadata in the private source through an explicit reviewed commit.
   Never force-push or reset a host's source.
3. Before fresh enrollment, preserve each host's native source and
   `~/.local/state/chezmoi-sync/applied-revision` in the private migration backup.
   After verifying the archive, clear only the old applied-revision marker so the
   new worker performs fresh enrollment. Do not delete the native source to force
   onboarding.
4. Deploy the matching worker and source revision, verify that host's fresh
   enrollment, plain-file contents, provisioned credential selection, and timer
   journal, then explicitly start its timer. Record activation and sync evidence
   per host; do not infer fleet activation from a successful build or another
   host's run.

Before resuming timers, verify that each source is clean and fast-forwardable,
that a fresh host can bootstrap all declared plain settings, that only fully
provisioned credential templates render, and that no secret payload enters the
source or diagnostic output. Exercise empty-file capture and peer receipt,
same-target conflict preservation, backup-failure retry, disjoint changes, and
rejected-push recovery in the isolated regression setup. Treat metadata/ignore
changes as explicit admin changes, not runtime captures.

```bash
systemctl --user status chezmoi-sync.timer
systemctl --user start chezmoi-sync.service
journalctl --user -u chezmoi-sync.service -n 40 --no-pager
git -C ~/.local/share/chezmoi log -5 --oneline
```

1. Close an app before applying files it rewrites on exit.
2. Capture an explicitly selected, managed **plain** file:

   ```bash
   chezmoi re-add "$HOME/.config/btop/btop.conf"
   chezmoi chattr +empty "$HOME/.config/btop/btop.conf"
   chezmoi diff "$HOME/.config/btop/btop.conf"
   ```

All declared plain-file source entries carry the `empty_` attribute so
zero-byte files remain managed and round-trip to peers. Restore the attribute
immediately after manual `re-add`, before reviewing or committing.

3. Review changes in the separate source and reconcile same-target conflicts
   deliberately; neither side's edit is discarded.
4. Provision runtime secrets before applying:

   ```bash
   chezmoi --no-tty apply
   chezmoi verify --exclude scripts
   ```

For operational proof, prefer the user service and inspect its journal and
applied-revision marker. Verification must use the service's `UMask=0022` and
secret-selection environment (`CHEZMOI_EXPECTED_SECRETS`,
`CHEZMOI_GH_HOSTS`). A whole-source `chezmoi verify --exclude scripts` may
report intentionally unselected empty credential-parent directories; that
alone does not show that selected settings failed. Verify the declared plain
targets and only secret destinations whose runtime dependencies are provisioned.
Do not broaden template selection or delete ignored empty directories just to
clear a whole-source report.

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

## Source recovery capsule

A private source recovery capsule, excluding Git metadata and rendered credentials,
is also retained at:

`~/.local/state/chezmoi-migration/fleet-source-auto-20261005T194537Z.tar`

SHA256: `3e2f9c3593ebacca1c2e9ee8030325a622484fe65fbd299b7d721801b73a51ab`.

It contains the initial published revision; use the remote for later changes.

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
