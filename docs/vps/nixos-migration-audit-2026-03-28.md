# VPS Migration Audit

This file captures the audit side of the VPS migration work. It is the detailed
snapshot of the source system that the later migration planning builds on.

## Focus

- current host state at audit time
- services and data that matter for migration
- unmanaged or imperative parts that would need to be carried forward or
  replaced

## Place In The Section

Use this as the starting point when you need the original context for the VPS
migration. The backup plan and manifest build on this audit, while the restore
runbook assumes the preserved set has already been decided.

## Related Docs

- [README.md](README.md)
- [nixos-running-services-backup-and-migration-plan-2026-03-28.md](nixos-running-services-backup-and-migration-plan-2026-03-28.md)
- [nixos-running-services-backup-manifest-2026-03-28.md](nixos-running-services-backup-manifest-2026-03-28.md)
