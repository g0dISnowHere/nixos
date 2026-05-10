# Secrets Commands

Quick lookup for the repo's SOPS operator commands.

## Core Checks

```bash
scripts/secrets | tail -n 20
scripts/secrets doctor | tail -n 20
scripts/secrets doctor --fix | tail -n 20
scripts/secrets doctor --full-test | tail -n 20
scripts/secrets validate-policy | tail -n 20
scripts/secrets validate-access --actor all | tail -n 20
scripts/secrets sync-policy --check | tail -n 20
```

## Create And Update

```bash
scripts/secrets create --scope services.fleet-test --name example.env | tail -n 20
scripts/secrets add-host --host <name> --user-scope djoolz | tail -n 20
scripts/secrets add-host --host <name> --no-user-scopes | tail -n 20
scripts/secrets register-host --host <name> | tail -n 20
scripts/secrets register-host --host <name> --force-host-rotate | tail -n 20
scripts/secrets user-scope --user djoolz --add-host <name> | tail -n 20
scripts/secrets user-scope --user djoolz --remove-host <name> | tail -n 20
scripts/secrets sync-policy | tail -n 20
```

## Retirement And Recovery

```bash
scripts/secrets retire-host --host <name> --dry-run | tail -n 20
scripts/secrets retire-host --host <name> | tail -n 20
scripts/secrets recover-access --host <name> | tail -n 20
scripts/secrets recover-access --host <name> --target-operator-recipient age1... | tail -n 20
```

## Pre-Merge Checks

Run these before merging changes to secrets policy tooling:

```bash
scripts/tests/secrets-policy-roundtrip.sh | tail -n 20
python3 -m py_compile scripts/secrets-lib/policy.py | tail -n 20
bash scripts/secrets-workflows/validate-policy.sh | tail -n 20
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel | tail -n 20
nix eval .#homeConfigurations."djoolz@workstation".activationPackage | tail -n 20
```

For policy-mutation changes, also run dry-run smoke tests against the affected workflows:

```bash
scripts/secrets user-scope --user <existing-scope> --add-host <existing-host> --dry-run | tail -n 20
scripts/secrets user-scope --user <new-scope> --add-host <existing-host> --create --dry-run | tail -n 20
scripts/secrets retire-host --host <existing-host> --dry-run | tail -n 20
```

## Current Lifecycle Notes

- `add-host` is the onboarding path for new hosts.
- `register-host` is for existing hosts only.
- `user-scope` manages `users.<name>` membership explicitly.
- `retire-host` is the supported path for removing shared host access.
- `recover-access` is for restoring operator decryptability from a still-working
  machine, not for ordinary host onboarding.

## Related Docs

- [docs/secrets-workflows.md](/home/djoolz/Documents/01_config/mine/docs/secrets-workflows.md)
- [secrets/README.md](/home/djoolz/Documents/01_config/mine/secrets/README.md)
