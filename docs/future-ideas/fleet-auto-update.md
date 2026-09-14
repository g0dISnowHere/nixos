# Historical: Branch-Safe Fleet Auto-Update

This proposal is superseded.

Fleet deployment, remote activation, closure transfer, and rollback belong to
[`deploy-rs`](../architecture/deployment-and-remote-builds.md), invoked with:

```bash
nix run .#deploy-fleet
```

`modules/nixos/system/autoupgrade.nix` and `scripts/update-system.sh` only
maintain their current host. Each scheduled run:

1. fast-forwards its configured existing checkout from `origin/main`;
2. runs `nix flake update`, commits, and pushes changed `flake.lock`;
3. synchronizes pnpm global packages and uv tools for the checkout owner;
4. runs `nixos-rebuild switch --flake .#<current-host>`.

The update path never clones a deployment checkout, selects a remote target, or
activates another host.
