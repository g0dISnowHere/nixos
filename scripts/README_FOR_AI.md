# AI Notes For `scripts/`

This file is a local-area supplement to [`AGENTS.md`](../AGENTS.md). It applies
only to work inside `scripts/` and must not be treated as a second repo-wide
source of truth.

## Role Of `scripts/`

Use `scripts/` for operator-facing orchestration and practical workflow glue.
Do not move repo policy into shell scripts when that policy belongs in Nix or
canonical docs.

## Design Rules

- keep the root of `scripts/` small and operator-facing
- prefer one orchestrator per operational domain
- organize below that by scope first, feature second
- keep orchestration, inspection, UI prompts, and workflow mutations separate
- default command behavior should be read-only when practical
- require explicit confirmation before destructive or state-changing actions
- keep recovery paths separate from normal convenience flows

## Preferred Layout

When a script family grows, prefer:

- `scripts/<domain>`
- `scripts/<domain>-lib/`
- `scripts/<domain>-workflows/`

Put only domain entrypoints at the root when they are intended to be run
directly by an operator.

## UX Rules

- optimize for clear operator workflows, not shell cleverness
- prefer guided diagnosis before mutation
- present bounded choices instead of making risky guesses
- show what will change before changing it
- end mutating workflows with validation

## Secrets Workflow Notes

For SOPS-related work:

- treat the orchestrator as a doctor/dispatcher, not as one giant workflow
- classify new-host bootstrap separately from broken existing-host access
- never rewrite recipient state until decryptability is proven with a valid
  existing key
- keep operator-key recovery separate from ordinary host registration
