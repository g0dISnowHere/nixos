# Future Idea: Branch-Safe Fleet Auto-Update

## Summary

Use `modules/nixos/system/autoupgrade.nix` as the declarative layer for
scheduled updates and `scripts/update-system.sh` as the operational entrypoint.
Scheduled jobs only operate on `origin/main`; day-to-day development stays on
other branches. The intended default deployment checkout is `~/nixos-deploy`.

## Topology

- `albaldah` is the only scheduled updater host
- `centauri` and `mirach` are scheduled consumer hosts
- scheduled automation only reads or writes `origin/main`
- manual development and pushes can happen from any machine on non-`main`
  branches

## Module Role

The NixOS module should own:

- host mode (`updater` or `consumer`)
- timer schedule
- repo path
- repo user for git/SSH operations
- remote and branch guard
- validation mode
- root-owned `systemd` service/timer wiring
- a bootstrap service that can be started automatically on `nixos-rebuild switch`

## Script Role

The shell script should own:

- branch and cleanliness checks for scheduled runs
- first-run bootstrap of `~/nixos-deploy` when the deployment checkout is absent
- a dedicated bootstrap mode used by the activation-triggered bootstrap service
- `git fetch` / fast-forward logic
- `nix flake update` on the updater host
- validation before `switch`
- `flake.lock` commit and push on the updater host
- `nixos-rebuild switch`
- post-switch reboot and stale-process summary

## Safety Rules

- scheduled jobs do nothing unless the checkout is on `main`
- scheduled jobs do nothing if tracked changes are present on `main`
- no automatic merge, rebase, stash, or force-push
- updater hosts only switch after a successful push when `flake.lock` changed
- consumer hosts never mutate `flake.lock`

## Privilege Model

The timer runs as a system service so rebuilds happen with root privileges.
Git operations still use the configured repo user so existing SSH keys continue
to work without moving repository credentials to root.
