# Secrets

This repo uses `sops-nix` with `age` recipients.

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
- `secrets/services/shared/...`

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

### Host key

Each machine also needs a recipient.

This repo enables `sops-nix`, and each NixOS host can generate a stable local
age identity at:

```text
/var/lib/sops-nix/key.txt
```

That host-local key is used at activation time to decrypt secrets assigned to
that machine.

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

- creates `~/.config/sops/age/keys.txt` if missing
- creates `~/.ssh/id_ed25519` if missing
- manages local key material only; SSH client config still belongs in Home Manager
- prints the operator `age` public key for `.sops.yaml`
- prints the SSH public key for remote `authorized_keys`
- prints the SSH key converted to an `age` recipient for `.sops.yaml`

For now you need at least:

- one operator recipient for `djoolz`
- one recipient for `centauri`
- one recipient for `mirach`

Later add more recipients for future hosts like the VPS.

### 2. Update `.sops.yaml`

Replace the placeholders in [.sops.yaml](../.sops.yaml).

Current structure:

```yaml
keys:
  - &djoolz age1replace...
  - &centauri age1replace...
  - &mirach age1replace...
```

Example after replacement:

```yaml
keys:
  - &djoolz age1operatorrecipient
  - &centauri age1centaurirecipient
  - &mirach age1mirachrecipient
```

The creation rules in `.sops.yaml` determine which recipients can decrypt which
files based on path.

### 3. Create a secret file

Create a plaintext file in the right location first.

Example:

```bash
mkdir -p secrets/services/shared
cp secrets/services/shared/example.env.example secrets/services/shared/example.env
```

Then edit it before encrypting:

```bash
$EDITOR secrets/services/shared/example.env
```

### 4. Encrypt a file

Encrypt in place with `sops`:

```bash
sops --encrypt --in-place secrets/services/shared/example.env
```

If `.sops.yaml` is set correctly, `sops` will automatically pick the right
recipients from the file path.

### 5. Edit an encrypted file

Use:

```bash
sops secrets/services/shared/example.env
```

Or with an explicit editor:

```bash
EDITOR=nano sops secrets/services/shared/example.env
```

### 6. Decrypt temporarily for inspection

```bash
sops --decrypt secrets/services/shared/example.env
```

Do not commit decrypted secrets back into the repo.

## How To Choose Paths

Use these rules:

- secret shared by multiple hosts: `secrets/services/shared/...`
- secret only for `centauri`: `secrets/machines/centauri/...`
- secret only for `mirach`: `secrets/machines/mirach/...`
- secret shared by you and both machines: `secrets/users/djoolz/...`

Examples:

- Docker registry token used on both hosts: `secrets/services/shared/registry.env`
- VPS-only app secret later: `secrets/machines/strato-vps/app.env`
- machine-local backup key for `mirach`: `secrets/machines/mirach/restic.env`

## Wiring Secrets Into Nix

This repo already enables `sops-nix` in the flake and imports the base system
module from [modules/nixos/system/secrets.nix](../modules/nixos/system/secrets.nix).

Typical NixOS example:

```nix
{
  sops.secrets."registry_env" = {
    sopsFile = ../../secrets/services/shared/registry.env;
    format = "dotenv";
    owner = "root";
    mode = "0400";
  };
}
```

Then point your service at the rendered secret file path in `/run/secrets/...`.

For file-shaped secrets like YAML, `.env`, or INI, prefer mounting or pointing
services at the generated file rather than copying plaintext into Nix strings.

## Typical Workflow

1. Generate recipients on each machine.
2. Update `.sops.yaml`.
3. Create the plaintext secret file in the correct `secrets/` path.
4. Encrypt it with `sops --encrypt --in-place`.
5. Reference it from a NixOS or Home Manager module.
6. Run a fast eval:

```bash
nix eval 'path:.#nixosConfigurations.centauri.config.system.build.toplevel'
nix eval 'path:.#nixosConfigurations.mirach.config.system.build.toplevel'
```

7. Deploy the target host.

## Rotating Secrets

To rotate a secret:

1. open the encrypted file with `sops`
2. replace the value
3. save and commit the encrypted result
4. deploy the hosts that consume it

To rotate recipients:

1. add the new recipient to `.sops.yaml`
2. re-encrypt affected files:

```bash
sops updatekeys --yes secrets/services/shared/example.env
```

3. remove the old recipient only after every required host or operator key has
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

Before real use, you still need to:

- replace placeholder recipients in `.sops.yaml`
- create actual encrypted files under `secrets/`
- wire each real secret into the owning module
