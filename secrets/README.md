# Secrets

This README is the subtree guide for `secrets/`. Keep repo-wide documentation
policy in `docs/` and `AGENTS.md`; keep this file focused on secret handling in
this directory.

For the canonical operator workflow, use
[`docs/secrets-workflows.md`](../docs/secrets-workflows.md).
For a quick command list, use
[`docs/reference/secrets-commands.md`](../docs/reference/secrets-commands.md).

This repo uses `sops-nix` with `age` recipients.

For day-to-day operator use, the `sops` CLI should be available on hosts where
the `djoolz` NixOS user module is applied. That binary now comes from the
system profile, not from Home Manager.

Use it for:

- shared machine secrets
- Docker and service credentials
- host-specific deployable secrets
- user secrets that truly need to be reproducible across machines

Do not use it for:

- browser logins
- ad hoc CLI auth that can stay local
- a single shared outgoing SSH private key for multiple hosts

Keep interactive desktop secrets in GNOME keyring when they do not need to be
declaratively distributed.

## Layout

- `users/` for shared user secrets that genuinely need repo-managed distribution
- `machines/` for host-specific secrets
- `services/` for application and Docker secrets

Examples:

- `secrets/users/djoolz/...`
- `secrets/machines/centauri/...`
- `secrets/machines/mirach/...`
- `secrets/services/<name>/...`

## Concepts

### Recipient

A recipient is a public key allowed to decrypt a secret.

In this repo, recipients are stored in [.sops.yaml](../.sops.yaml).
They look like:

```yaml
keys:
  - &djoolz age1...
  - &centauri age1...
  - &mirach age1...
```

These `age1...` values are public keys, not secrets.

### Operator key

This is your own `age` keypair. It lets you decrypt and edit secrets directly
from your workstation even if a target host is offline or not yet rebuilt.

Recommended: keep one operator key outside the repo at:

```text
~/.config/sops/age/keys.txt
```

If this file is missing, operator-side decrypt commands and
`scripts/secrets validate-access --actor operator ...` will fail even when the
machine's `/var/lib/sops-nix/key.txt` still works for activation-time
decryption.

### Machine sops-nix key

Each machine also needs a recipient.

This repo enables `sops-nix`, and each NixOS host can generate a stable local
age identity at:

```text
/var/lib/sops-nix/key.txt
```

That host-local key is used at activation time to decrypt secrets assigned to
that machine.

Use the public key from `/var/lib/sops-nix/key.txt` as the machine recipient in
`.sops.yaml`.

### SSH key

The normal SSH keypair at `~/.ssh/id_ed25519` is separate.

Use it for:

- SSH client authentication
- populating remote `authorized_keys`

Do not treat it as the default `sops-nix` machine decryption key unless you
intentionally redesign the host secret model around that choice.

## SSH Guidance

Do not share one private SSH key across `centauri`, `mirach`, and future
servers.

Use one SSH private key per machine, then distribute the corresponding public
keys to every target you want that machine to access.

Good model:

- `centauri` has its own `~/.ssh/id_ed25519`
- `mirach` has its own `~/.ssh/id_ed25519`
- remote hosts trust both public keys in `authorized_keys`

Bad model:

- one private SSH key encrypted in the repo and copied to multiple machines

## Bootstrap

### 1. Generate keys

Use [scripts/ssh-pubkey-to-age.sh](../scripts/ssh-pubkey-to-age.sh) on each machine:

```bash
scripts/ssh-pubkey-to-age.sh
```

If you intentionally want to rotate existing keys:

```bash
scripts/ssh-pubkey-to-age.sh --force
```

This script:

- creates `/var/lib/sops-nix/key.txt` if missing
- rotates only `/var/lib/sops-nix/key.txt` when run with `--force`
- never creates or modifies `~/.config/sops/age/keys.txt`
- never creates or modifies `~/.ssh/id_ed25519`
- prints any existing operator `age` public key for `.sops.yaml`
- prints the machine `sops-nix` age public key for `.sops.yaml`
- prints any existing SSH public key for remote `authorized_keys`
- prints the SSH-derived `age` recipient only as an optional separate value

For now you need at least:

- one operator recipient for `djoolz`
- one machine `sops-nix` recipient for `centauri`
- one machine `sops-nix` recipient for `mirach`

Later add more recipients for future hosts like the VPS.

For new host onboarding, use:

```bash
scripts/secrets
scripts/secrets add-host --host <name>
```

That workflow:

- reads the machine recipient from `/var/lib/sops-nix/key.txt`
- adds the host to `flake/secrets-policy.nix`
- requires explicit user-scope membership selection
- regenerates `.sops.yaml`
- rekeys relevant secrets
- verifies the host can decrypt those secrets with its own `sops-nix` key

Use `--user-scope <name>` for explicit non-interactive onboarding and
`--no-user-scopes` when the host should not inherit any current user scope.

For existing host registration or refresh, use:

```bash
scripts/secrets register-host
```

That workflow currently:

- infers the current host alias from `hostname -s` by default
- reads the machine recipient from `/var/lib/sops-nix/key.txt`
- updates the host recipient in `flake/secrets-policy.nix`
- regenerates `.sops.yaml`
- rekeys relevant user, service, and machine-local secrets for that host
- verifies the host can decrypt those secrets with its own `sops-nix` key

Important:

- `scripts/secrets register-host` is not a cold-start recovery path
- it uses `sops updatekeys`, so your local operator key file at
  `~/.config/sops/age/keys.txt` must already decrypt the targeted secrets
- if your operator key has changed and no longer matches the recipients already
  embedded in those files, recover them with a valid existing key first, then
  re-run the registration flow

Use `--dry-run` to preview and `--force-host-rotate` only when you are
intentionally changing a host recipient.

For explicit host key rotation with clearer intent, use:

```bash
scripts/secrets rotate-host --host <name>
```

For explicit user scope membership changes, use:

```bash
scripts/secrets user-scope --user <name> --add-host <host>
```

For safe host retirement, use:

```bash
scripts/secrets retire-host --host <name> --dry-run
```

That workflow:

- removes the host from policy
- regenerates `.sops.yaml`
- rekeys shared secrets to drop that host
- refuses to proceed while machine-scoped secrets still exist for that host

### 2. Update policy and render `.sops.yaml`

Edit [flake/secrets-policy.nix](../flake/secrets-policy.nix), then render and
validate the derived config:

```bash
scripts/secrets sync-policy
scripts/secrets validate-policy
```

`.sops.yaml` is committed derived state and should match the rendered policy.

### 3. Create a secret file

Prefer the policy-aware helper:

```bash
scripts/secrets create --scope services.fleet-test --name example.env
```

That workflow:

- asks for or accepts an existing scope
- chooses a valid target path inside that scope
- seeds a format-appropriate template
- opens your editor on a plaintext temp file
- encrypts the result to the correct repo path

Manual creation still works when you need it.

Create a plaintext file in the right location first.

Example:

```bash
mkdir -p secrets/services/fleet-test
cp secrets/services/fleet-test/example.env.example secrets/services/fleet-test/example.env
```

Then edit it before encrypting:

```bash
$EDITOR secrets/services/fleet-test/example.env
```

For the shared `djoolz` login password secret, prefer the helper script instead
of editing hashes manually:

```bash
scripts/set-user-password-secret.sh
```

That command securely prompts for the password, hashes it with `mkpasswd`,
and rewrites `secrets/users/djoolz/password.yaml` with `sops`. Re-running the
same script later rotates the password secret in place.

### 4. Encrypt a file

Encrypt in place with `sops`:

```bash
sops --encrypt --in-place secrets/services/fleet-test/example.env
```

If `.sops.yaml` is set correctly, `sops` will automatically pick the right
recipients from the file path.

### 5. Edit an encrypted file

Use:

```bash
sops secrets/services/fleet-test/example.env
```

Or with an explicit editor:

```bash
EDITOR=nano sops secrets/services/fleet-test/example.env
```

### 6. Decrypt temporarily for inspection

```bash
sops --decrypt secrets/services/fleet-test/example.env
```

Do not commit decrypted secrets back into the repo.

## How To Choose Paths

Use these rules:

- secret shared by multiple hosts: `secrets/services/<name>/...`
- secret only for `centauri`: `secrets/machines/centauri/...`
- secret only for `mirach`: `secrets/machines/mirach/...`
- secret shared by you and both machines: `secrets/users/djoolz/...`

Examples:

- Docker registry token used on both hosts: `secrets/services/fleet-test/registry.env`
- VPS-only app secret later: `secrets/machines/strato-vps/app.env`
- machine-local backup key for `mirach`: `secrets/machines/mirach/restic.env`

## Wiring Secrets Into Nix

This repo already enables `sops-nix` in the flake and imports the base system
module from [modules/nixos/system/secrets.nix](../modules/nixos/system/secrets.nix).

Typical NixOS example:

```nix
{
  sops.secrets."registry_env" = {
    sopsFile = ../../secrets/services/fleet-test/registry.env;
    format = "dotenv";
    owner = "root";
    mode = "0400";
  };
}
```

Then point your service at the rendered secret file path in `/run/secrets/...`.

For file-shaped secrets like YAML, `.env`, or INI, prefer mounting or pointing
services at the generated file rather than copying plaintext into Nix strings.

For local operator-side validation, use:

```bash
scripts/secrets validate-policy
scripts/secrets validate-access --actor operator --host centauri
```

The example operator validation path decrypts:

- `secrets/services/fleet-test/sops-test.yaml`
- `secrets/users/djoolz/password.yaml`

and verifies the decrypted YAML contains the expected fields before any secret
is wired into a NixOS option such as `users.users.<name>.hashedPasswordFile`.

## Typical Workflow

1. Generate recipients on each machine.
2. Update `flake/secrets-policy.nix`.
3. Run `scripts/secrets sync-policy`.
4. Create the plaintext secret file in the correct `secrets/` path.
5. Encrypt it with `sops --encrypt --in-place`.
6. Reference it from a NixOS or Home Manager module.
7. Run a fast eval:

```bash
nix eval 'path:.#nixosConfigurations.centauri.config.system.build.toplevel'
nix eval 'path:.#nixosConfigurations.mirach.config.system.build.toplevel'
```

8. Deploy the target host.

## Rotating Secrets

To rotate a secret:

1. open the encrypted file with `sops`
2. replace the value
3. save and commit the encrypted result
4. deploy the hosts that consume it

To rotate recipients:

1. update `flake/secrets-policy.nix`
2. run `scripts/secrets sync-policy`
3. re-encrypt affected files:

```bash
sops updatekeys --yes secrets/services/fleet-test/example.env
```

4. remove the old recipient only after every required host or operator key has
   been updated

## Recovery Notes

- If your operator `age` private key is lost, you can only edit secrets if some
  other remaining recipient can still decrypt them.
- If a host loses `/var/lib/sops-nix/key.txt`, secrets encrypted only to that
  host recipient will need to be rekeyed.
- Keep your operator `age` private key backed up securely outside the repo.

## Current Repo State

These files matter right now:

- [.sops.yaml](../.sops.yaml)
- [scripts/ssh-pubkey-to-age.sh](../scripts/ssh-pubkey-to-age.sh)
- [modules/nixos/system/secrets.nix](../modules/nixos/system/secrets.nix)

Before broader use, you still need to:

- add real named service scopes under `secrets/services/`
- create additional encrypted files under `secrets/`
- wire each real secret into the owning module
