# Secrets Commands

Quick lookup for the repo's SOPS operator commands.

## Core Checks

```bash
scripts/secrets
scripts/secrets doctor
scripts/secrets doctor --fix
scripts/secrets doctor --full-test
scripts/ssh-pubkey-to-age.sh
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

## Pre-Merge Checks

Run these before merging changes to secrets policy tooling:

```bash
scripts/tests/secrets-policy-roundtrip.sh
python3 -m py_compile scripts/secrets-lib/policy.py
bash scripts/secrets-workflows/validate-policy.sh
nix eval .#nixosConfigurations.centauri.config.system.build.toplevel
nix eval .#homeConfigurations."djoolz@workstation".activationPackage
```

For policy-mutation changes, also run dry-run smoke tests against the affected workflows:

```bash
scripts/secrets user-scope --user <existing-scope> --add-host <existing-host> --dry-run
scripts/secrets user-scope --user <new-scope> --add-host <existing-host> --create --dry-run
scripts/secrets retire-host --host <existing-host> --dry-run
```

## Current Lifecycle Notes

- `add-host` is the onboarding path for new hosts.
- onboarding bootstraps missing local operator and host age keys before host
  registration.
- `register-host` is for existing hosts only.
- `user-scope` manages `users.<name>` membership explicitly.
- `retire-host` is the supported path for removing shared host access.
- `recover-access` is for restoring operator decryptability from a still-working
  machine, not for ordinary host onboarding.

## Related Docs

- [docs/secrets-workflows.md](/home/djoolz/Documents/01_config/mine/docs/secrets-workflows.md)
- [secrets/README.md](/home/djoolz/Documents/01_config/mine/secrets/README.md)
