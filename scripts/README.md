# Scripts

This directory holds supporting utilities around the main flake. The scripts are
part of the workflow, but they are intentionally not the architectural center
of the repo.

## Design Role

The repo tries to keep policy in Nix and documentation, while using scripts for
practical glue:

- wrapping common operational tasks
- making local workflows faster
- handling one-off helper tasks that do not belong in the flake model itself

That keeps the system understandable without pretending everything needs to be a
Nix module.

## Script Architecture

Treat the root of `scripts/` as a small set of operator-facing orchestrators.
They are the commands a human is expected to run directly.

Design rules:

- organize by scope first, feature second
- keep top-level `scripts/` entries focused on orchestration and user workflow
- put implementation detail below the orchestrators, not beside them at the top
- prefer one clear entrypoint per domain such as `scripts/secrets` or
  `scripts/update`
- default subcommands should be safe and read-only when practical
- keep destructive or state-changing operations behind explicit confirmation
- separate diagnosis from mutation even when one command can guide both

For script families that grow beyond one or two files, prefer a scoped layout:

- `scripts/<domain>`
- `scripts/<domain>-lib/`
- `scripts/<domain>-workflows/`

This keeps the root readable while still reserving the top-level domain name for
the operator-facing entrypoint.

## Current Direction

The intended direction is to treat the root of `scripts/` as a set of
orchestrators for distinct operational domains. As those domains grow, move
implementation into domain-scoped subtrees instead of expanding the root with
more helper files.

For the secrets domain specifically:

- use a single operator-facing orchestrator as the front door
- make `doctor` the safe default entrypoint
- let the orchestrator inspect state, suggest the correct workflow, and prompt
  before writes
- keep workflow implementations focused and separately callable

## Current Script Groups

- update and rebuild helpers
- key and secret helpers
- status and workflow helpers
- older personal automation

Current update helpers include:

- `scripts/update-system.sh` for branch-safe scheduled and manual update flows
  in `updater` and `consumer` modes
  - the timer/service path runs as root for `nixos-rebuild switch`
  - git operations still run as the configured repo user so existing SSH keys
    remain usable

Current secret helpers include:

- `scripts/secrets` as the operator-facing SOPS orchestrator
  - `doctor` for guided inspection
  - `sync-policy` for rendering `.sops.yaml` from `flake/secrets-policy.nix`
  - `validate-policy` and `validate-access` for split validation
  - `add-host` for explicit host onboarding
  - `user-scope` for `users.<name>` membership management
- `scripts/ssh-pubkey-to-age.sh` for machine `sops-nix` key bootstrap and
  inspection of existing operator and SSH keys
- `scripts/register-sops-host.sh` as the lower-level rekey-and-verify helper
  used by `scripts/secrets add-host` and `scripts/secrets register-host`
- `scripts/set-user-password-secret.sh` for provisioning or rotating the
  encrypted `secrets/users/<name>/password.yaml` secret

## Reading This Directory

Treat these scripts as convenience layers around the core design. If you are
trying to understand the repo, start with the flake structure and docs first,
then use the scripts as examples of how the system is operated in practice.

For AI-oriented implementation guidance scoped to this subtree, see
[`scripts/README_FOR_AI.md`](./README_FOR_AI.md). That file supplements
[`AGENTS.md`](../AGENTS.md) for `scripts/` only and is not a second repo-wide
source of truth.

## Related Docs

- [README.md](../README.md)
- [docs/auto-commit-flake-lock.md](../docs/auto-commit-flake-lock.md)
- [docs/secrets-workflows.md](../docs/secrets-workflows.md)
- [docs/reference/secrets-commands.md](../docs/reference/secrets-commands.md)
- [docs/reference/useful-commands.md](../docs/reference/useful-commands.md)
