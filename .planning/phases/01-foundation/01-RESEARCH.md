# Phase 01: Foundation - Research Findings

**Objective:** What do I need to know to PLAN this phase well?

## 1. Ragenix Integration (INFRA-01, INFRA-02)

### Flake Input
- `ragenix` can be added as a flake input in `flake.nix` using its GitHub URL (e.g., `github:ryantm/agenix`).
- The input should be configured to expose the `agenix` module.

### NixOS Module
- The `ragenix` NixOS module is typically enabled in `configuration.nix` (or a machine-specific configuration) by adding `age.enable = true;`.
- Key configuration options include:
    - `age.secrets.<name>.file`: Path to the encrypted `.age` file.
    - `age.secrets.<name>.owner`: Owner of the decrypted secret.
    - `age.secrets.<name>.group`: Group of the decrypted secret.
    - `age.secrets.<name>.mode`: File permissions of the decrypted secret.
    - `age.identityPaths`: List of paths to SSH private keys used for decryption (e.g., `/etc/ssh/ssh_host_ed25519_key`).

## 2. SSH Service Configuration (INFRA-03, INFRA-04)

### Enabling SSH Service
- The SSH service is enabled in NixOS by setting `services.openssh.enable = true;` in the system configuration.
- This automatically generates host keys (e.g., `ssh_host_ed25519_key`, `ssh_host_rsa_key`) in `/etc/ssh/`.

### Retrieving Public Host Keys
- The public host keys are located at `/etc/ssh/ssh_host_ed25519_key.pub` and `/etc/ssh/ssh_host_rsa_key.pub`.
- These public keys are needed to encrypt secrets using `ragenix`. They can be extracted using `cat /etc/ssh/ssh_host_ed25519_key.pub` or `ssh-keygen -y -f /etc/ssh/ssh_host_ed25519_key`.
- For multi-machine encryption, the public keys of *all* target machines must be provided to `ragenix`.

## 3. Secrets Directory (INFRA-05)

### Location
- A dedicated directory (e.g., `secrets/`) should be created at the root of the repository to store encrypted `.age` files. This directory should be tracked by git.

### Ragenix Configuration
- `ragenix` can be configured to automatically discover secrets in a specified directory using `age.secrets.path = "/path/to/secrets";` or by explicitly listing each secret. Explicit listing is generally preferred for clarity and control.

## 4. Automated Encryption Script (`encrypt-secret.sh`)

### Script Logic
- The script should take the secret name (e.g., `personal/github_pat`) as an argument.
- It should securely prompt the user for the plaintext secret value (e.g., using `read -s`).
- It needs to dynamically retrieve the public host keys for `centauri` and `mirach`. This can be done by reading the public key files directly from `/etc/ssh/` on each machine (if the script is run on the respective machine) or by having them pre-configured/passed as arguments. For a multi-machine setup, it's best to have a known location for all public keys.
- The `ragenix` command to encrypt would look like:
    ```bash
    echo "$SECRET_VALUE" | ragenix -r "ssh-ed25519 AAAA..." -r "ssh-ed25519 BBBB..." > secrets/"$SECRET_NAME".age
    ```
    where `AAAA...` and `BBBB...` are the public keys of `centauri` and `mirach` respectively.
- The script should ensure the output `.age` file is placed in the `secrets/` directory.

### Public Key Management for Script
- To make the script portable and work for encrypting secrets for multiple machines from a single machine (e.g., `centauri`), the public keys of all machines (`centauri` and `mirach`) need to be accessible to the script.
- A common approach is to store these public keys in a known location within the repository (e.g., `keys/centauri.pub`, `keys/mirach.pub`) or fetch them dynamically if the machines are reachable via SSH. For simplicity in Phase 1, storing them in the repository is a good starting point.

---
*Research gathered: 2026-02-06*
