# Dotfiles With chezmoi And sops-nix

Status: selected native-file migration, private source repository and guarded
Centauri publication/fleet receive implemented. Broad discovery and automatic
enrollment remain proposals. See the [operational runbook](../reference/chezmoi.md)
for ownership, synchronization policy, recovery proof and offline host handoff.

## Goals

- Manage native application settings without rewriting them into Nix.
- Track configuration changes made through editors and application UIs.
- Find newly created configuration without mirroring the entire home directory.
- Share portable settings across hosts while keeping host-specific values local.
- Reuse chezmoi and the existing SOPS policy instead of building another dotfile
  manager.
- Keep ordinary config editing independent of rebuilds and deployment checkouts.

## Ownership

| Layer | Responsibility |
| --- | --- |
| NixOS / Home Manager | Packages, environment, services, and installation of chezmoi and automation |
| chezmoi | Selected native config files, templates, host differences, and a separate Git source repository |
| sops-nix | Runtime secret provisioning with declared access, ownership, and permissions |
| Discovery automation | Identify new config candidates and report coverage and exclusions |

Each destination has one owner. A migration removes the corresponding Home
Manager file declaration or custom copy activation before chezmoi takes over.
Existing declarative settings may stay in Home Manager; this proposal does not
require moving all user configuration.

chezmoi normally installs regular files. Apps can replace those files during
atomic saves without breaking a link into a checkout. Changes to live files
still need capture into chezmoi's source state.

## Repository And Host Differences

Use a separate chezmoi Git repository and its normal source-state layout. Do not
introduce a custom profile tree, generic linker, or copy-list framework.

Keep the mutable source checkout independent of `~/nixos-deploy` so application
edits do not dirty the system auto-update checkout. A NixOS submodule is not
required for this architecture. Decide later whether deployment needs a pinned
reference to the dotfiles repository; do not make live settings depend on a
submodule checkout.

Use chezmoi templates and `.chezmoiignore` for host differences. Prefer plain
files where hosts share the same contents. Template only the values that need
variation, such as local paths or host-specific settings.

The separate repository should be private unless its contents have been reviewed
for publication. Private hosting does not replace secret handling.

## Editing, Capture, And Deployment

For managed plain files, `chezmoi re-add` captures live modifications into source
state and preserves encrypted-file attributes. It does not overwrite templates
or enroll arbitrary unmanaged files.

- Plain app-written config: edit normally, then capture with `re-add`.
- Templated config: edit the template and inspect the rendered diff before apply.
  UI-written changes need reconciliation into the template; automatic capture
  cannot infer the intended host-variable expression.
- Cross-host changes: exchange Git revisions, resolve source conflicts, inspect
  the destination diff, then apply.

The selected allowlist now uses guarded background capture on Centauri and
receive-only synchronization elsewhere. Local edits, unexpected source changes
and unsafe active-app writes block applies rather than being silently merged.
Do not schedule unconditional `chezmoi update` during rebuilds; its default
autostash/rebase is not the fleet's conflict policy.

Keep an independent backup of live settings before rollout. chezmoi and Git
history do not guarantee recovery of uncaptured local changes.

## SOPS Integration

### Preferred On NixOS: Provision Secrets With sops-nix

Keep encrypted secrets and access membership under the existing
[secrets workflow](../secrets-workflows.md). Reuse its policy and operator commands;
do not introduce a second hand-maintained SOPS recipient inventory.

sops-nix decrypts secrets into runtime files. Let applications reference those
files directly when supported. Otherwise, a chezmoi template can read an
explicitly configured runtime secret path and render the application config.

- Run secret-consuming chezmoi operations only after provisioning completes.
- Grant the invoking user access only to the required secrets.
- Keep decrypted values out of Nix evaluation and store-built derivations.
- Give rendered secret-bearing files restrictive permissions.
- Exclude provisioned secret files, private keys, and rendered secret-bearing
  destinations from automatic enrollment or plaintext capture.
- Keep templates in source control, not their rendered plaintext output.

### Portable Alternative: Invoke SOPS From A Template

chezmoi's `output` template function can invoke `sops --decrypt`. This requires
SOPS and a decryption identity on that host. It is command-based integration,
not a native chezmoi SOPS encryption backend. Prefer sops-nix on NixOS to avoid
replicating provisioning and access logic.

chezmoi also supports its own encrypted-file workflow, including age. That is
separate from SOPS. Sharing an age identity does not make their encrypted file
formats interchangeable. Choose one secret workflow per managed item.

## Automatic Discovery: Remaining Requirement

chezmoi supplies management and deployment, but broad discovery needs additional
automation. A discovery-only report does not satisfy the full goal of automatic
tracking; the enrollment and capture policy must be settled before claiming the
feature complete.

Proposed scan scopes:

- Top-level home dotfiles and selected tool configuration directories.
- `~/.config/`.
- Flatpak `~/.var/app/*/config/`.
- Selected configuration locations beneath `~/.local/share/`.

Do not scan Desktop, Downloads, projects, caches, or the entire home as a Git
working tree. Exclude existing Home Manager-owned paths, SOPS outputs and keys,
known credentials, histories, browser profiles, and disposable runtime state.
Report skipped, oversized, and unclassified paths with reasons rather than
silently treating them as covered. Mixed config/state directories need per-app
rules; directory size alone cannot identify settings.

Use application-level policies rather than one hand-maintained entry per file:

- Shared: enroll and capture approved portable configuration within the app's
  specified scope.
- Host-local: track approved config without applying it on other hosts.
- Excluded: credentials, generated files, and state outside the intended scope.

Unknown apps remain candidates until the policy defines safe enrollment. If
unattended capture of unknown configuration is required, specify encryption
before its first Git commit and host isolation first. Ignore lists and secret
scanners cannot guarantee secret-free plaintext publication.

Do not synchronize live databases without an application-supported export/import
workflow. GNOME dconf and other database-backed settings need separate treatment
if the goal is portable settings rather than byte-level backup.

## Migration And Acceptance

1. Inventory ownership, live destinations, and secret-bearing paths. Diff the
   legacy Centauri dotfiles tree against repository content and preserve actual
   differences. Modification timestamps alone do not prove newer content.
2. Trial chezmoi on a small set of plain, non-secret settings. Prove live-edit
   capture, reviewed apply, and recovery without changing unrelated settings.
3. Establish the separate source repository and host differences. Prove that two
   hosts receive their intended values and that a divergent live edit is not
   silently lost.
4. Trial one SOPS-backed setting. Prove provisioning order, user access, file
   permissions, and absence of plaintext secrets in Git and the Nix store.
5. Migrate each selected destination, removing obsolete Home Manager ownership
   and checkout-path dependencies in the same cutover. Keep packages and session
   wiring in Nix.
6. Implement discovery and agreed enrollment rules. Exercise new-file detection,
   exclusions, coverage reporting, and source/live edit conflicts before enabling
   unattended capture.
7. Promote the landed design into
   [Home Manager And Dotfiles](../architecture/home-manager-dotfiles-strategy.md)
   and the dotfiles operator docs. Retire this proposal after migration.

Acceptance requires ordinary app saves to keep working, capture to preserve user
changes, host differences to remain isolated, and discovery to account for
untracked configuration. No success claim based only on rebuild evaluation.

## Open Decisions

- Repository location, visibility, and whether Nix deployment needs a pinned
  dotfiles revision.
- Initial applications and which existing declarative settings stay in Nix.
- Enrollment policy for unknown apps, especially automatic encrypted host-local
  capture versus review before enrollment.
- Background capture frequency and conflict handling; whether commit/push should
  ever run unattended.
- Secret paths and provisioning order for user-level chezmoi operations.

## Upstream References

- [chezmoi host differences](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/)
- [chezmoi re-add](https://www.chezmoi.io/reference/commands/re-add/)
- [chezmoi encryption](https://www.chezmoi.io/user-guide/encryption/)
- [chezmoi output template function](https://www.chezmoi.io/reference/templates/functions/output/)
- [sops-nix provisioning](https://github.com/Mic92/sops-nix#how-it-works)
