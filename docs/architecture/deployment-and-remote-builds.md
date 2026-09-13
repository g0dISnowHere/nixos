# Deployments and Remote Builds

## Deployment Contract

Run deployments through:

```bash
nix run .#deploy-fleet
```

`deploy-fleet` evaluates the checkout from which you run it. It does not deploy a separately fetched Git revision. A dirty tracked worktree participates in the evaluation; flake inputs resolve through `flake.lock`.

The wrapper deploys each configured node in a separate deploy-rs invocation.
It continues after an unreachable node and reports every failed node after
attempting the rest. It skips the host from which it runs because Tailscale
refuses self-SSH activation.

The deployment machine evaluates and builds each profile locally, then
deploy-rs copies the completed closure to its target. Do not pass deploy-rs
`--remote-build`: that makes each deployment target build its own profile.

## Source Transfer Is Required

The deployment machine evaluates the local flake and builds the derivations.
Nix copies missing source paths, including the flake source NAR and required
input paths, during those local builds. This preserves the exact checkout
selected by the operator.

Avoiding source transfer requires a different workflow: commit and push a
revision, arrange for a builder to fetch that revision into its own checkout,
build there, and deploy only the resulting closures. That workflow cannot
deploy uncommitted local changes.

## Transport and Activation

Each independent deployment:

1. builds its profile on the deployment machine;
2. copies that closure to its target over SSH;
3. activates the target as `root` with automatic and magic rollback enabled.

A deployment launched from a target host skips that host because
self-activation through its Tailscale hostname is refused. Update it locally
with `sudo nixos-rebuild switch --flake .#<hostname>`.

## Implementation Map

- `outputs.nix`: root `deploy` output and the independent-node `deploy-fleet` wrapper.
- `flake/lib.nix`: deploy-rs nodes, activation profiles, rollback policy, and target hostnames.
