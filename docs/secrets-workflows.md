# Secrets Workflows

This is the canonical operator guide for the repo's SOPS workflow.

The intent is to keep secret policy deterministic, keep `.sops.yaml` rendered
from one source of truth, and make lifecycle mutations explicit instead of
hiding them behind ad hoc manual edits.

## Design Boundaries

The secrets workflow is split into two layers:

- `flake/secrets-policy.nix` defines intended public policy
- `scripts/secrets` provides operator UX for inspection, mutation, and recovery

Keep those responsibilities separate:

- Nix owns declared access intent
- scripts own guided mutation and validation

## Current Policy Model

The repo currently treats these as the public inventory:

- one operator alias with one or more public recipients
- known hosts and their public recipients
- explicit `users.<name>` host membership
- explicit `services.<name>` host membership

Rules:

- access is explicit, not inferred from host class or role
- every managed secret file must map to exactly one scope
- machine secrets are always operator plus the owning host
- service and user scope membership is a host list, not a dynamic rule

## Current Command Surface

The operator front door is `scripts/secrets`.

Current workflows:

- `scripts/secrets doctor`
- `scripts/secrets sync-policy`
- `scripts/secrets validate-policy`
- `scripts/secrets validate-access`
- `scripts/secrets create`
- `scripts/secrets add-host`
- `scripts/secrets register-host`
- `scripts/secrets retire-host`
- `scripts/secrets user-scope`
- `scripts/secrets recover-access`

`doctor` is the safe default. It stays read-only unless you opt into
`--fix`.

## Lifecycle Workflows

### Create A Secret

Use:

```bash
scripts/secrets create --scope services.fleet-test --name example.env
```

This is the preferred path for new managed secrets because it keeps file
placement aligned with policy ownership.

### Add A Host

Use:

```bash
scripts/secrets add-host --host <name>
```

This is the first-class onboarding path for a new host.

Current behavior:

- bootstraps the local operator age key if missing
- reads the host recipient from `/var/lib/sops-nix/key.txt`
- adds the host to `flake/secrets-policy.nix`
- requires explicit user-scope membership selection
- regenerates `.sops.yaml`
- rekeys relevant secrets
- verifies host decrypt access

Important:

- this refuses to guess user-scope membership
- onboarding should be run on the target machine so the local operator and
  host age keys can be generated there when missing
- use `--user-scope <name>` repeatedly for non-interactive runs
- use `--no-user-scopes` when the host should not join any current user scope

### Register An Existing Host

Use:

```bash
scripts/secrets register-host --host <name>
```

This workflow is for a host that already exists in policy and needs its current
host recipient refreshed or re-verified.

Current behavior:

- reads the host recipient from `/var/lib/sops-nix/key.txt`
- updates the host recipient in `flake/secrets-policy.nix`
- regenerates `.sops.yaml`
- rekeys relevant secrets
- verifies host decrypt access

Important:

- this is not a cold-start recovery path
- the operator key must already decrypt the targeted secrets before rekey

### Manage User Scope Membership

Use:

```bash
scripts/secrets user-scope --user <name> --add-host <host>
scripts/secrets user-scope --user <name> --remove-host <host>
scripts/secrets user-scope --user <name> --host <host> --host <host>
```

This workflow manages `users.<name>` policy entries directly.

Current behavior:

- creates a missing user scope when run with `--create`
- updates exact or incremental host membership
- regenerates `.sops.yaml`
- rekeys affected `secrets/users/<name>/...` files
- refuses to retire a user scope while files still exist under that scope

### Retire A Host

Use:

```bash
scripts/secrets retire-host --host <name> --dry-run
```

Current behavior:

- removes the host from policy
- regenerates `.sops.yaml`
- rekeys shared secrets to drop that host
- refuses to proceed while machine-scoped secrets still exist for that host

This is considered baseline-capable today, but v1 still wants clearer
first-class rotation and stronger guided remediation in `doctor --fix`.

### Recover Operator Access

Use:

```bash
scripts/secrets recover-access --host <name>
```

Use this from a machine that still has a working private key matching embedded
recipients in the affected secrets.

Current behavior:

- updates operator recipients in policy
- regenerates `.sops.yaml`
- rekeys affected secrets with a working source key
- optionally validates the target operator key immediately

## Validation Model

Validation is intentionally split:

- `validate-policy`
  - policy correctness
  - path ownership
  - unknown host references
  - rendered `.sops.yaml` drift
- `validate-access`
  - operator decryptability
  - host decryptability for relevant secrets

This keeps deterministic policy failures separate from runtime key-access
failures.

## Remaining V1 Work

The workflow is useful now, but a coherent v1 still needs:

1. `rotate-host` as a first-class workflow with clearer intent than
   `register-host --force-host-rotate`
2. richer `doctor --fix` guidance for create, rotate, retire, and
   partial-verification states
3. end-to-end live testing of the mutation flows on real machines

The current baseline is already good enough in these areas:

- deterministic policy model
- rendered `.sops.yaml`
- policy versus access validation split
- fast versus broad validation split
- `create` workflow
- `add-host` workflow
- `user-scope` workflow
- `retire-host` baseline
- improved `doctor` output

## Verification Targets

The current design is healthy when all of these are true:

- `scripts/secrets validate-policy` passes
- `scripts/secrets sync-policy --check` passes
- `scripts/secrets validate-access --actor operator --host <host>` passes from
  a working operator machine
- mutating workflows end with validation
