# VPS Backup Manifest

This file is the inventory side of the VPS migration work. It is the detailed
record of what belongs in the backup set and what should be tracked through
restore.

## Focus

- services being preserved
- data groups and backup items
- restore and validation tracking

## Place In The Section

The manifest is the concrete companion to the backup plan. The plan explains
the preservation approach; the manifest records the actual items that need to
be captured and later checked off.

## Related Docs

- [README.md](README.md)
- [nixos-running-services-backup-and-migration-plan-2026-03-28.md](nixos-running-services-backup-and-migration-plan-2026-03-28.md)
- [backup-reimport-runbook-2026-03-28.md](backup-reimport-runbook-2026-03-28.md)
