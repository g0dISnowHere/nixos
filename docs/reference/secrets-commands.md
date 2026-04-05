# Secrets Commands

Quick lookup for the repo's SOPS operator commands.

## Core Checks

```bash
scripts/secrets
scripts/secrets doctor
scripts/secrets doctor --fix
scripts/secrets doctor --full-test
scripts/secrets validate-policy
scripts/secrets validate-access --actor all
scripts/secrets sync-policy --check
```

## Create And Update

```bash
scripts/secrets create --scope services.fleet-test --name example.env
scripts/secrets add-host --host <name> --user-scope djoolz
scripts/secrets add-host --host <name> --no-user-scopes
scripts/secrets register-host --host <name>
scripts/secrets register-host --host <name> --force-host-rotate
scripts/secrets user-scope --user djoolz --add-host <name>
scripts/secrets user-scope --user djoolz --remove-host <name>
scripts/secrets sync-policy
```

## Retirement And Recovery

```bash
scripts/secrets retire-host --host <name> --dry-run
scripts/secrets retire-host --host <name>
scripts/secrets recover-access --host <name>
scripts/secrets recover-access --host <name> --target-operator-recipient age1...
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
