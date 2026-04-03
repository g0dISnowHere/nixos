# VPS Docs

This section covers the VPS-specific slice of the repo. It connects the
integrated `albaldah` machine with the migration history and the surrounding
service-preservation work.

This is canonical documentation for the VPS area. Dated investigations and
historical migration notes remain separate from this section's role as the VPS
entrypoint.

## Why This Section Exists

The VPS story is structurally different from the local workstation and homelab
machines:

- it has remote-install concerns
- it has migration and preservation concerns
- it has a clearer boundary between historical source state and the new
  repo-managed target state

That makes it worth documenting as its own area rather than scattering the
context across host files and findings.

## Main Themes

- migration context
  - where the VPS setup came from and what was observed on the source side
- backup and restore planning
  - how the preserved service set is framed
- secret handling
  - credential review and follow-up cleanup
- reference material
  - older standalone artifacts that explain the historical path

## How To Read It

Use this section as a bridge between the host-local `albaldah` files and the
detailed findings. The files here describe the VPS as an area of work, not just
as a single machine definition.

## Files

- [nixos-migration-audit-2026-03-28.md](nixos-migration-audit-2026-03-28.md)
- [nixos-running-services-backup-and-migration-plan-2026-03-28.md](nixos-running-services-backup-and-migration-plan-2026-03-28.md)
- [nixos-running-services-backup-manifest-2026-03-28.md](nixos-running-services-backup-manifest-2026-03-28.md)
- [backup-reimport-runbook-2026-03-28.md](backup-reimport-runbook-2026-03-28.md)
- [secret-rotation-checklist-2026-03-28.md](secret-rotation-checklist-2026-03-28.md)
- [strato-vps/README.md](strato-vps/README.md)
