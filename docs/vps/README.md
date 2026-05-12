# VPS Docs

This section covers VPS slice of repo. It ties `albaldah`, migration history,
service-preservation work together.

This page = canonical VPS entrypoint. Dated findings and migration notes stay
separate.

## Why This Section Exists

VPS story differs from workstation and homelab:

- remote install matters
- migration and preservation matter
- old source state vs new repo-managed state has hard boundary

So VPS gets own doc area, not scattered crumbs.

## Main Themes

- migration context: where VPS came from, what source side looked like
- backup and restore planning: how preserved services framed
- secret handling: credential review, cleanup follow-up
- reference material: older artifacts showing historical path

## How To Read It

Use this section as bridge between host-local `albaldah` files and detailed
findings. Files here describe VPS as work area, not only one host definition.

## Files

- [nixos-migration-audit-2026-03-28.md](nixos-migration-audit-2026-03-28.md)
- [nixos-running-services-backup-and-migration-plan-2026-03-28.md](nixos-running-services-backup-and-migration-plan-2026-03-28.md)
- [nixos-running-services-backup-manifest-2026-03-28.md](nixos-running-services-backup-manifest-2026-03-28.md)
- [backup-reimport-runbook-2026-03-28.md](backup-reimport-runbook-2026-03-28.md)
- [crowdsec-auth-domains.md](crowdsec-auth-domains.md)
- [crowdsec-on-albaldah.md](crowdsec-on-albaldah.md)
- [../reference/crowdsec-commands.md](../reference/crowdsec-commands.md)
- [secret-rotation-checklist-2026-03-28.md](secret-rotation-checklist-2026-03-28.md)
- [strato-vps/README.md](strato-vps/README.md)
