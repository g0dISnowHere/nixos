# SOPS Policy And Orchestrator

This incubator note tracks the remaining design work around the SOPS
orchestrator after the baseline implementation landed.

It is not the canonical operator guide.

Use [`docs/secrets-workflows.md`](../secrets-workflows.md) for the stable
operator workflow and [`docs/reference/secrets-commands.md`](../reference/secrets-commands.md)
for quick command lookup.

## V1 Gap Summary

If "finish" means a coherent, usable v1 with explicit lifecycle coverage, the
remaining minimum is now:

1. `rotate-host`
2. stronger `doctor --fix`
3. end-to-end live testing of mutation flows

Everything after that is polish rather than missing core capability.

## What Is Already Good Enough

These pieces are already strong enough to treat as baseline:

- deterministic policy model
- rendered `.sops.yaml`
- policy versus access validation split
- fast versus broad validation split
- `create-secret` workflow
- `add-host` workflow
- `users.<name>` scope management
- canonical operator docs
- `retire-host` baseline
- improved `doctor` output

## Missing Core Capability

### Rotate Host

Still needed:

- `rotate-host` as a first-class workflow
- distinct from generic register or refresh behavior
- clearer intent and confirmation

### Better `doctor --fix`

Still needed:

- richer guided actions for create, rotate, retire, and partial-verification
  states

## Runtime Proving

The remaining non-doc proving work is live runtime validation:

- live test of `register-host` on a new host
- live test of `add-host`
- live test of `retire-host`
- live test of recovery flow
- verify `doctor --full-test` behavior on another machine
