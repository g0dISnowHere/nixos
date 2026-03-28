# VPS Backup And Migration Plan

This file covers the preservation plan for the services kept during the VPS
migration. It narrows the audit down to the service set and data classes that
actually need to survive the move.

## Focus

- which services are in scope
- which categories of data must be preserved
- the order and grouping of backup work

## Place In The Section

This document sits between the audit and the restore runbook. The audit tells
you what exists, this plan decides what matters, and the restore runbook
describes how the preserved set gets brought back.

## Related Docs

- [README.md](README.md)
- [nixos-migration-audit-2026-03-28.md](nixos-migration-audit-2026-03-28.md)
- [nixos-running-services-backup-manifest-2026-03-28.md](nixos-running-services-backup-manifest-2026-03-28.md)
- [backup-reimport-runbook-2026-03-28.md](backup-reimport-runbook-2026-03-28.md)
