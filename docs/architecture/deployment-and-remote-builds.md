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
After deploy-rs reports a successful, confirmed activation, `deploy-fleet` and
the `deploy-rs` wrapper run `nix-collect-garbage --delete-older-than 30d`
remotely as `root` on each fully confirmed target. For a multi-target
`deploy-rs` invocation with `--rollback-succeeded false`, confirmed targets
before a later failure are still collected. When deploy-rs reports that it is
rolling back previously successful targets, the wrapper skips GC because those
activations are being revoked. GC errors are reported separately and do not
change the deployment result. Dry activation and boot-only deployments do not
run GC. The existing weekly system GC timer remains enabled; this post-deployment
cleanup is an additional pass.

For a single target, use the wrapper rather than upstream deploy-rs directly:

```bash
nix run .#deploy-rs -- .#<hostname>
```

The `deploy-rs` wrapper preserves deploy-rs target, profile, group, and
external-file selections. `deploy-fleet` also honors group filters and reads
its node set from an external file when `--file` is selected. External `--file`
node enumeration and GC settings use deploy-rs' pinned no-flake evaluation
transform, including its profile-path derivation handling. Collection is based
on deploy-rs profile build, activation, and confirmation events, so only fully
confirmed selected targets are considered. `--ssh-user`, `--sudo`, `--ssh-opts`,
and `--hostname` are used for the collector connection. GC failures remain
nonfatal. Dry/boot deployments skip GC.

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

### Alhena WSL MTU

Alhena sets its Linux `eth0` MTU to 1500, matching the Windows WSL virtual
interface; `tailscale0` remains at 1280. An underlay MTU of 1280 caused
packet-size-dependent loss: 1028-byte tunnel packets passed, but 1228- and
1280-byte packets received no replies. ML-KEM SSH key exchange and deployment
closure transfers stalled. Restoring `eth0` to 1500 made full-size tunnel
packets and ML-KEM key exchange succeed.

`networking.interfaces.eth0.mtu` alone generated a `.link` rule but did not
preserve the MTU across a WSL instance restart. Alhena's `wsl-eth0-mtu.service`
waits for the existing `eth0` device and applies that configured value before
Tailscale starts. A WSL instance restart verified `eth0` at 1500, `tailscale0`
at 1280, three full-size ping replies and a fresh SSH connection without a
manual MTU adjustment.

To verify a restart, check PID 1's start time and the service execution time:
`ps -p 1 -o lstart=` and
`systemctl show wsl-eth0-mtu.service -p ExecMainStartTimestamp -p Result`.
WSL may retain the shared kernel, so an unchanged kernel boot ID does not
mean the distribution's init was not restarted.

Check the affected path with `ping -M do -s 1252 -c 3 alhena`.
The Curve25519 SSH setting avoids the large handshake but does not fix
bulk-transfer packet loss.

## Implementation Map

- `outputs.nix`: root `deploy`, post-confirmation GC helper, and deployment wrappers.
- `flake/lib.nix`: deploy-rs nodes, activation profiles, rollback policy, and target hostnames.
