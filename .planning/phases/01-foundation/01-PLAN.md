# Phase 01: Foundation - Plans

## Plan 01-01: Integrate Ragenix Flake Input and Module

**wave**: 1
**depends_on**: []
**files_modified**: flake.nix, nixos/configurations.nix
**autonomous**: true

### Tasks

1.  **Add Ragenix Flake Input:**
    *   Modify `flake.nix` to include `ragenix` as an input, pointing to its GitHub repository.
    *   Ensure the `agenix` module is exposed for use in NixOS configurations.

2.  **Enable Ragenix NixOS Module:**
    *   In `nixos/configurations.nix` (or a relevant common module), enable the `age.enable = true;` option.

### Verification Criteria

-   `flake.nix` contains a `ragenix` input.
-   The NixOS configuration successfully enables the `age` module.

### Must Haves

-   Ragenix is integrated into the NixOS flake.
-   The Ragenix NixOS module is active and available for configuration.

---

## Plan 01-02: Enable SSH Services and Retrieve Host Keys

**wave**: 1
**depends_on**: []
**files_modified**: nixos/machines/centauri/configuration.nix, nixos/machines/mirach/configuration.nix
**autonomous**: true

### Tasks

1.  **Enable SSH on Centauri:**
    *   In `nixos/machines/centauri/configuration.nix`, set `services.openssh.enable = true;`.

2.  **Enable SSH on Mirach:**
    *   In `nixos/machines/mirach/configuration.nix`, set `services.openssh.enable = true;`.

3.  **Retrieve Centauri's Public Host Key:**
    *   After rebuilding `centauri`, execute `ssh-keygen -y -f /etc/ssh/ssh_host_ed25519_key` (or similar for other key types) to get the public key. Store this temporarily.

4.  **Retrieve Mirach's Public Host Key:**
    *   After rebuilding `mirach`, execute `ssh-keygen -y -f /etc/ssh/ssh_host_ed25519_key` (or similar for other key types) to get the public key. Store this temporarily.

### Verification Criteria

-   SSH service is active on both `centauri` and `mirach`.
-   Public host keys for both machines are successfully retrieved.

### Must Haves

-   Both `centauri` and `mirach` have SSH services running.
-   The public host keys for both machines are available for use in `ragenix` encryption.

---

## Plan 01-03: Create Secrets Directory and Automated Encryption Script

**wave**: 2
**depends_on**: ["01-02"]
**files_modified**: .gitignore, secrets/ (new directory), encrypt-secret.sh (new file)
**autonomous**: false

### Tasks

1.  **Create Secrets Directory:**
    *   Create a new directory named `secrets/` at the root of the repository.

2.  **Develop `encrypt-secret.sh` Script:**
    *   Create an executable shell script `encrypt-secret.sh` in the repository root.
    *   The script should:
        *   Accept a secret name (e.g., `personal/github_pat`) as its first argument.
        *   Securely prompt the user for the plaintext secret value using `read -s`.
        *   Dynamically retrieve the public host keys for `centauri` and `mirach` (e.g., from a known location like `keys/centauri.pub`, `keys/mirach.pub` which will be created in a later step, or by prompting the user for them). For now, assume the public keys are provided as arguments or hardcoded for testing.
        *   Use `ragenix -r <centauri_pub_key> -r <mirach_pub_key>` to encrypt the secret.
        *   Save the encrypted output to `secrets/<secret_name>.age`.

3.  **Update `.gitignore`:**
    *   Add `secrets/*.age` to `.gitignore` to prevent accidental plaintext commits.

### Verification Criteria

-   The `secrets/` directory exists.
-   The `encrypt-secret.sh` script is executable.
-   Running `encrypt-secret.sh test/secret` successfully creates `secrets/test/secret.age` with valid encrypted content.
-   `.gitignore` correctly ignores `.age` files within the `secrets/` directory.

### Must Haves

-   A dedicated directory for encrypted secrets exists.
-   A functional and secure script for encrypting new secrets is available.
-   Encrypted secrets are prevented from being accidentally committed in plaintext.
