# OrcaSlicer native preset synchronization

Status: selected Linux native presets migrated with chezmoi and sops-nix.
The former whole-profile symlink/Git plan is superseded. Windows synchronization
has not been implemented or verified.

## Implemented boundary

Centauri supplies the conflict-winning native user library:

- nine process presets and two filament presets as plain native JSON;
- four machine presets as private templates reading SOPS runtime files.

Centauri, Mirach and Karaka are the GUI allowlist, with native synchronization
active on all three. The mutable source is separate from the NixOS checkout.
chezmoi installs regular native files; apps do not write into Nix-store symlinks
or a live Git checkout.

`OrcaSlicer.conf`, generated system/vendor profiles, caches, logs, OTA updates,
window state, printer selection and unrelated device state remain host-local.
Copying a whole profile would mix portable presets with credentials and machine
state. Do not enroll `system/`, the entire `user/` tree or generated backups.

Native OrcaSlicer 2.3.2 recognized the migrated custom printer, filament and
process presets in an isolated GUI profile. No printer connection, printing or
slicing was performed. Library availability does not synchronize the active
printer selection or every preference.

## Editing

Capture explicitly selected plain process/filament presets using native chezmoi
operations. Reconcile cross-host conflicts with Centauri before applying.
Credentialed machine-preset edits belong in
`secrets/users/djoolz/orca-machine-presets.yaml`, under the existing user SOPS
policy. Redeploy runtime secrets, then apply the templates; never capture a
rendered credentialed preset as plaintext Git source.

See the [chezmoi runbook](../reference/chezmoi.md) for exact ownership, backup and
actual extraction recovery, credential handling, and offline rollout requirements.
