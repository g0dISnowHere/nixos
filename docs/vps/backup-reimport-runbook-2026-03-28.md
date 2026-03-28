# VPS Backup Reimport

This file covers the restore side of the VPS migration work. It is the document
to use after the backup set already exists and the target system is ready to
receive it.

## Focus

- restore order
- service bring-up sequence
- validation after each restore stage

## Place In The Section

This sits after the audit and preservation planning. The audit explains the
source system, the plan and manifest define what to preserve, and this runbook
describes how that preserved set gets reintroduced on the target side.

## Related Docs

- [README.md](README.md)
- [nixos-running-services-backup-and-migration-plan-2026-03-28.md](nixos-running-services-backup-and-migration-plan-2026-03-28.md)
- [nixos-running-services-backup-manifest-2026-03-28.md](nixos-running-services-backup-manifest-2026-03-28.md)
