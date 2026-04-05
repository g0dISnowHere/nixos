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
  secrets-lib/
    inspect.sh
    ui.sh
  secrets-workflows/
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
- `scripts/secrets-lib/` holds shared inspection and prompt logic
- `scripts/secrets-workflows/` holds focused state-changing or validation flows
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

# Minimal Nix Secrets Inventory, Not a Policy Engine

  ## Summary

  Implement a small, explicit Nix secrets inventory that becomes the source of truth for public secret policy and renders the committed .sops.yaml. Keep the model intentionally
  minimal so it does not turn into a policy engine: no rule language, no implicit role-based access, no dynamic derivation for secret grants.

  The core split stays:

  - Nix owns intended public policy and fleet structure
  - scripts own mutation, rekeying, recovery, and guided workflows

  This directly supports your goals:

  - add/remove machines without remembering machine-specific setup history
  - keep one portable user environment everywhere by default
  - share Docker/service secrets safely as the number of secrets grows
  - make systems feel as identical as possible unless an exception is explicit

  ## Key Changes

  - Add one canonical data file, flake/secrets-policy.nix, containing only:
      - operator
          - explicit single operator alias
          - one or more operator public recipients
      - hosts
          - hostname
          - host public recipient
          - optional minimal display metadata only, such as class label for UI/validation
      - scopes
          - users.<name> with explicit host membership
          - services.<name> with explicit host membership
          - machines.<hostname> implicit per host, not manually enumerated as a separate policy object
  - Generate and commit .sops.yaml from that inventory.
      - remove hand-maintained anchors and creation rules
      - remove services/shared/ entirely except for migrating the current placeholder file
      - replace it with named service scopes under services/<name>/...
  - Add flake library helpers:
      - self.lib.secretsPolicy for normalized structured policy
      - self.lib.renderSopsConfig for deterministic .sops.yaml rendering
  - Add one policy reconciliation command:
      - scripts/secrets sync-policy
      - --check fails on drift
      - --diff shows the generated delta
      - default mode updates the committed .sops.yaml
  - Update scripts/secrets to consume the Nix policy instead of guessing from YAML.
      - use the explicit operator alias
      - use policy-defined host inventory for doctor/recovery/onboarding prompts
      - use scope membership from policy for named services and user scopes
  - Rewrite or remove old one-off scripts as needed.


  - Do not build a policy engine.
  - Do not use host roles or metadata to grant secret access.
  - Do not invent a general expression language for scope membership.
  - Do not let mkNixosSystem or machine-role logic become the secret-policy source.
  - Do not move private keys or rekey operations into Nix.

  Access decisions in v1 are always explicit:

  - a service scope lists allowed hosts
  - a user scope lists allowed hosts
  - a machine scope belongs to exactly one host

  ## Test Plan

  - Deterministic generation
      - rendering .sops.yaml from flake/secrets-policy.nix is stable
      - scripts/secrets sync-policy --check passes only when committed output matches rendered output
  - Scope behavior
      - users.<name> renders recipients for operator plus explicitly listed hosts
      - services.<name> renders recipients for operator plus explicitly listed hosts
      - machines.<hostname> renders recipients for operator plus that host only
  - Migration behavior
      - services/shared/ is removed safely
      - the placeholder secrets/services/shared/sops-test.yaml is migrated to a named service scope, e.g. services/fleet-test/
  - Orchestrator behavior
      - doctor no longer infers operator alias from key order
      - recovery guidance points to the explicit operator alias and relevant scope membership
      - host add/remove guidance follows policy inventory, not ad hoc YAML parsing
  - Validation behavior
      - host in inventory but missing recipient fails validation
      - scope referencing unknown host fails validation
      - orphaned machine path or policy drift is reported cleanly

  ## Assumptions And Defaults

  - One explicit primary operator alias is sufficient for v1.
  - Service scopes list allowed hosts explicitly; hosts do not opt themselves into services.
  - services/shared/ can be removed because it is only a placeholder now.
  - Host metadata stays minimal and is only for validation or UI, never for access policy.
  - One portable user environment remains the baseline everywhere; machine exceptions stay explicit and outside the secret-policy model unless needed for validation.
