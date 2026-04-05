# SOPS Policy And Orchestrator

This incubator note tracks the current direction and implemented baseline for a
low-friction, deterministic SOPS workflow in this repo.

It is still not the canonical operator guide, but it now reflects the actual
shape in the tree instead of mixing multiple competing plans.

## Design Summary

The secrets workflow is split into two layers:

- Nix owns intended public secret policy and fleet structure
- scripts own inspection, mutation, recovery, and operator UX

The core goal is operational simplicity:

- adding or rotating a host should be explicit and deterministic
- `.sops.yaml` should be rendered from one source of truth
- operators should not need to remember path-specific YAML edits
- risky actions should stay guided and validated

## Implemented Baseline

### Policy Inventory

The repo now has a canonical public policy file at
`flake/secrets-policy.nix`.

It defines only:

- one operator alias and its public recipient list
- known hosts and their public recipients
- explicit user scope membership
- explicit service scope membership

It intentionally does not define:

- role-based secret grants
- dynamic scope rules
- mutation or rekey logic
- private key material

### Rendered `.sops.yaml`

`.sops.yaml` is now treated as committed derived state.

Current flow:

- edit `flake/secrets-policy.nix`
- run `scripts/secrets sync-policy`
- commit both the policy file and rendered `.sops.yaml`

The rendered config is deterministic and validated by:

- `scripts/secrets sync-policy --check`
- `scripts/secrets validate-policy`

### Script Entry Point

The operator front door remains `scripts/secrets`.

Current command shape:

```text
scripts/secrets doctor
scripts/secrets sync-policy
scripts/secrets validate-policy
scripts/secrets validate-access
scripts/secrets create
scripts/secrets register-host
scripts/secrets retire-host
scripts/secrets recover-access
```

`doctor` remains read-only by default and should classify common situations
before suggesting a next step.

### Validation Split

Validation is now deliberately split into two kinds:

- policy validation
  - inventory correctness
  - path ownership
  - unknown host references
  - rendered `.sops.yaml` drift
- access validation
  - operator decryptability
  - host decryptability for relevant secrets

This keeps deterministic policy errors separate from runtime key access errors.

## Current Rules

### Policy Rules

- access decisions are always explicit
- every managed secret file must map to exactly one scope
- service scopes list allowed hosts explicitly
- user scopes list allowed hosts explicitly
- machine secrets are always operator + owning host
- host metadata is UI or validation metadata only

### Safety Rules

- default command behavior should be read-only when possible
- never rekey before proving current operator decrypt access
- always show intended mutation targets before writes
- keep recovery separate from ordinary host registration
- end mutating workflows with validation

## Current Repo Shape

The placeholder shared service scope has been migrated away from
`secrets/services/shared/`.

The current example named service scope is:

- `secrets/services/fleet-test/`

That path is now covered by explicit policy instead of a catch-all shared
service rule.

## Remaining Work

The implemented baseline covers deterministic policy ownership, rendered
`.sops.yaml`, policy drift detection, scope-aware secret creation, host
registration and retirement on top of policy, and split validation.

Still desirable:

- richer `doctor` guidance for rotate and retire flows
- better operator-facing docs outside `docs/future-ideas/`

## Opinionated Defaults

These defaults are intentional:

- one operator alias is sufficient for v1
- multiple recipients under that alias are allowed for backup or recovery
- service membership should stay explicit, not inferred
- the portable user environment can justify adding new hosts to user scopes
  during onboarding, but service scope membership should still remain explicit

## Verification Targets

The current design is considered healthy when all of the following are true:

- `scripts/secrets validate-policy` passes
- `scripts/secrets sync-policy --check` passes
- `scripts/secrets validate-access --actor operator --host <host>` passes from
  a working operator machine
- mutating flows end with access validation
