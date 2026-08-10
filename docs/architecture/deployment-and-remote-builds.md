# Deployments and Remote Builds

## Deployment Contract

Run deployments through:

```bash
nix run .#deploy-fleet
```

`deploy-fleet` evaluates the checkout from which you run it. It does not deploy a separately fetched Git revision. A dirty tracked worktree participates in the evaluation; flake inputs resolve through `flake.lock`.

The wrapper passes these Nix build options when launched anywhere except
Albaldah:

```text
--builders 'ssh-ng://root@albaldah.wallaby-clownfish.ts.net x86_64-linux - 3 100 big-parallel - -'
--max-jobs 1
```

Eligible derivations build on Albaldah. The one local job is required for
`preferLocalBuild` derivations, including NixOS's firmware link farm; setting
`--max-jobs 0` makes those deployments fail. When launched on Albaldah, the
wrapper uses its local builder and does not configure Albaldah as its own
remote builder.

Do not pass deploy-rs `--remote-build`. That option makes each deployment
target build its own profile, which violates this contract.

## Source Transfer Is Required

Albaldah builds the derivations, but the deployment machine evaluates the local flake first. Nix copies missing source paths, including the flake source NAR and required input paths, to Albaldah before the build. This transfer preserves the exact local checkout selected by the operator.

Avoiding source transfer requires a different workflow: commit and push a revision, arrange for Albaldah to fetch that revision into its own checkout, build there, and deploy only the resulting closures. That workflow cannot deploy uncommitted local changes.

## Builder Access

The deployment machine's Nix daemon must authenticate to Albaldah as `root`
over `ssh-ng`. It needs Albaldah's host key, a usable root SSH identity, and
access to the Tailscale hostname. Albaldah must run Nix, accept the connection,
and trust the connecting user. Albaldah itself does not need this self-builder
configuration.

## Transport and Activation

Building and activation use separate connections:

1. Nix sends build inputs to Albaldah and retrieves completed output closures.
2. deploy-rs copies those closures to each target over SSH.
3. deploy-rs activates each target as `root` with automatic and magic rollback enabled.

A deployment launched from a target host cannot activate that same host through its Tailscale hostname: the self-SSH connection is refused. Build placement remains correct, but self-activation must use `sudo nixos-rebuild switch --flake .#<hostname>`; exclude that host from a fleet run.

## Implementation Map

- `outputs.nix`: `deploy-fleet` wrapper and forced remote-builder flags.
- `flake/lib.nix`: deploy-rs nodes, activation profiles, rollback policy, and target hostnames.
- `modules/nixos/system/albaldah-builder.nix`: Centauri's Albaldah builder access.
- `flake/deploy/default.nix`: adapter that exposes local flake deployment configuration to deploy-rs.
