# SOPS Orchestrator Proposal

This document captures the current implementation plan for a safer and more
guided SOPS operator workflow in this repo.

It is an incubator design note, not yet the canonical operator workflow.

## Goal

Provide a single operator-facing secrets entrypoint that:

- diagnoses current SOPS state
- classifies the problem or onboarding state
- suggests the correct workflow
- guides the operator through bounded choices
- requires explicit confirmation before writes
- validates the result after changes

The intent is to make secret operations frictionless without hiding risk.

## High-Level Model

Use one orchestrator as the front door and keep concrete operations in focused
workflow helpers.

The orchestrator should:

- inspect state
- decide which workflow applies
- prompt the user with explicit choices
- show previews before mutation
- dispatch to one workflow
- run post-change validation

It should not become one giant mutation script.

## Script Layout

The root of `scripts/` should expose operator-facing orchestrators only.

For the secrets domain, the intended layout is:

```text
scripts/
  secrets
  secrets/
    lib/
      inspect.sh
      ui.sh
    workflows/
      bootstrap-operator.sh
      register-host.sh
      create-secret.sh
      rotate-host-key.sh
      retire-host.sh
      validate.sh
```

Design rules:

- `scripts/secrets` is the operator entrypoint
- the default subcommand should be `doctor`
- `lib/` holds shared inspection and prompt logic
- `workflows/` holds focused state-changing or validation flows
- orchestration and mutation must stay separate

## Roles And Trust Boundaries

- operator key
  - human-managed `age` identity used to decrypt, edit, and rekey secrets
- host key
  - machine-local `/var/lib/sops-nix/key.txt` used for activation-time
    decryption
- `.sops.yaml`
  - intended recipient policy by path
- encrypted secret files
  - actual embedded recipient state that must match policy

Important distinction:

- host decrypt failure can be expected during new-host onboarding
- operator decrypt failure is a hard blocker for rekey operations

## States The Orchestrator Must Recognize

### Healthy Existing Host

- operator key exists
- host key exists
- hostname maps to a known alias
- recipients match `.sops.yaml`
- operator can decrypt the secrets it needs
- host can decrypt the secrets it should have

### New Host Not Yet Onboarded

- host key may or may not exist yet
- host alias may not exist in `.sops.yaml`
- host cannot decrypt any secrets yet

This is expected during bootstrap and must not be treated as a broken state.

### Existing Host With Drift

- host alias exists
- host key exists
- host recipient differs from `.sops.yaml`, or
- host should have access but cannot decrypt

### Operator Key Drift Or Loss

- operator key file missing, unreadable, or changed
- operator cannot decrypt current secrets

This blocks rekey and registration flows and must redirect to recovery or
operator bootstrap guidance.

### Recipient Drift

- encrypted file recipients no longer match `.sops.yaml`

### Policy Gaps

- secret paths not covered by creation rules
- host alias exists without matching machine-secret rule
- machine secret directories without matching alias/rule

## Workflows To Cover

The orchestrator should guide operators into one of these workflows:

1. bootstrap operator access
2. add or onboard a new host
3. register or refresh an existing host
4. rotate a host key
5. rotate the operator key
6. create a new secret
7. edit or rekey an existing secret
8. validate current secret access
9. retire a host
10. recover from lost operator access

The repo should not rely on one script trying to blur these together.

## `doctor` Behavior

`doctor` is the front door and the safe default mode.

It should:

- perform read-only inspection first
- summarize findings in plain language
- present a short list of valid next actions
- explain destructive implications briefly
- request confirmation before running mutations

Recommended interface shape:

```text
scripts/secrets doctor
scripts/secrets doctor --fix
scripts/secrets validate
scripts/secrets create
scripts/secrets rotate-host
scripts/secrets retire-host
```

`--fix` should only automate safe, bounded remediations. It must not silently
perform destructive rotations or recovery actions.

## Checks `doctor` Should Run

- required commands exist
- repo root and `.sops.yaml` exist
- operator key file exists and is readable
- host key file exists and is readable
- current hostname maps to a known alias, or can be overridden
- operator public key matches the expected configured operator recipient
- host public key matches the configured host recipient
- operator can decrypt representative managed secrets
- host can decrypt secrets it should receive
- encrypted recipients match `.sops.yaml`
- every secret path is covered by a creation rule

## Decision Model

Examples of guided branches:

### Missing Operator Key

Choices:

- show operator bootstrap steps
- try a different operator key path
- abort

### Missing Host Key

Choices:

- generate host key
- show details
- abort

### Unknown Host Alias

Choices:

- use detected hostname
- override host alias
- abort

### New Host Not Yet Registered

Choices:

- onboard host
- show affected secret paths
- abort

### Host Recipient Mismatch

Choices:

- preview recipient update and rekey
- rotate host key intentionally
- abort

### Operator Cannot Decrypt Existing Secrets

Choices:

- show recovery guidance
- try another operator key file
- abort

### Recipient Drift

Choices:

- preview rekey
- rekey now
- abort

## Safety Rules

- default behavior is read-only
- never rewrite `.sops.yaml` before proving an operator key can decrypt the
  existing secrets involved
- never run rekey operations without both pre-check and post-check validation
- always show a preview before recipient changes
- require explicit confirmation for destructive or locking-risk actions
- keep recovery separate from ordinary registration
- end every mutating workflow with validation

## New-Host Onboarding Flow

A brand new host must be treated as a normal onboarding case, not as a failure.

Expected flow:

1. ensure `/var/lib/sops-nix/key.txt` exists
2. read the host public key
3. ensure the host alias exists in `.sops.yaml`, or add it
4. ensure intended creation rules include that host where appropriate
5. verify the operator key can decrypt the existing targeted secrets
6. rekey those secrets to include the new host recipient
7. verify the host key can now decrypt them

Important:

- pre-registration host decrypt failure can be normal
- operator decrypt failure before rekey is never normal

## UX Rules

- optimize for operator clarity over shell cleverness
- present bounded choices instead of guessing
- explain consequences briefly, not abstractly
- show the exact files or recipients that will change
- keep interactive prompts consistent across workflows

## Implementation Notes

Initial implementation should favor small shell helpers and explicit command
composition over clever parsing.

Priority order:

1. shared inspection helpers
2. `doctor` entrypoint
3. host onboarding and registration workflow
4. validation workflow
5. create/rotate/retire workflows

The existing `register-sops-host.sh` logic can inform the new workflow but
should not define the long-term shape by itself.
