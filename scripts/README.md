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

## Script Groups

- update and rebuild helpers
- key and secret helpers
- status and workflow helpers
- older personal automation

Current secret helpers include:

- `scripts/ssh-pubkey-to-age.sh` for machine `sops-nix` key bootstrap and
  inspection of existing operator and SSH keys
- `scripts/register-sops-host.sh` for low-friction host registration: update
  one host recipient in `.sops.yaml`, rekey the relevant secrets, and verify
  host-side decryption
- `scripts/set-user-password-secret.sh` for provisioning or rotating the
  encrypted `secrets/users/<name>/password.yaml` secret

## Reading This Directory

Treat these scripts as convenience layers around the core design. If you are
trying to understand the repo, start with the flake structure and docs first,
then use the scripts as examples of how the system is operated in practice.

## Related Docs

- [README.md](../README.md)
- [docs/auto-commit-flake-lock.md](../docs/auto-commit-flake-lock.md)
- [docs/reference/useful-commands.md](../docs/reference/useful-commands.md)
