# Pitfalls Research: NixOS Secrets Management with agenix/ragenix

**Domain:** NixOS secrets management (age-based encryption)
**Researched:** 2026-02-06
**Confidence:** HIGH (official docs, community patterns, GitHub issues)

---

## Critical Pitfalls

### Pitfall 1: Bootstrap Chicken-and-Egg Problem with Fresh Installations

**What goes wrong:**
Fresh NixOS systems cannot decrypt secrets during `nixos-install` because SSH host keys don't exist yet. The decryption happens during activation (which requires the host key), but the host key is created during the same build. This creates a hard blocker preventing initial system deployment.

**Why it happens:**
agenix decrypts secrets using the target machine's SSH private key from `/etc/ssh/ssh_host_*_key`. On a new system, these keys don't exist until after the initial build completes. If the build requires secrets (e.g., for user passwords, service credentials), the bootstrap fails.

**How to avoid:**
- **Pre-generate host keys before deployment**: Create the ED25519 host key manually and place it on the deployment medium before running `nixos-install`
- **Use a two-pass deployment**: First deploy without secret-dependent features, then add secrets in a second rebuild
- **Enable SSH early**: Ensure `services.openssh.enable = true` is set even if secrets are disabled initially
- **Alternative for testing**: Use a dummy private key for initial setup, then rekey after the system is operational

**Warning signs:**
- "Error: No such file or directory" from rage during `nixos-install`
- Activation scripts fail with "cannot decrypt secret"
- Build succeeds but `nixos-rebuild switch` hangs during secret decryption
- Host keys missing from `/etc/ssh/` when expected

**Phase to address:**
Early phase (before infrastructure deployment) — must solve before adding first secret to a new machine. Consider adding host key generation as a prerequisite step in your deployment procedure.

---

### Pitfall 2: Host Key vs. User Key Confusion

**What goes wrong:**
Developers encrypt secrets with user SSH keys (e.g., `~/.ssh/id_ed25519.pub`) instead of the system's host key (`/etc/ssh/ssh_host_ed25519_key.pub`). The secret decrypts locally during development but fails at deployment because the target machine cannot decrypt it — it only has access to its own host key.

**Why it happens:**
User keys and host keys are conceptually similar (both ED25519 SSH keys) but serve different purposes. User keys are for authentication; host keys are for machine identity. agenix uses host keys for decryption at activation time (running as root), not user keys. This distinction is subtle and often missed.

**How to avoid:**
- **Golden rule**: Always encrypt with `/etc/ssh/ssh_host_ed25519_key.pub` from the target machine, not personal SSH keys
- **Verify in secrets.nix**: Add both your user key (for editing) AND the host key (for deployment)
  ```nix
  let
    user = "ssh-ed25519 AAAA...your-key...";
    centauri_host = "ssh-ed25519 AAAA...from-/etc/ssh-on-centauri...";
  in {
    "github-pat.age".publicKeys = [ user centauri_host ];
  }
  ```
- **Get host keys correctly**: Use `ssh-keyscan hostname` or copy from `/etc/ssh/ssh_host_ed25519_key.pub` on the target
- **Test decryption**: Run `age -d -i ~/.ssh/id_ed25519 secret.age` locally; run `agenix -d` on the target to verify

**Warning signs:**
- Local `agenix -d` works but `nixos-rebuild switch` fails with "cannot decrypt"
- Secrets work on development machine but not on remote
- Different decryption behavior between machines with the same secret

**Phase to address:**
Phase 1 (initial secrets setup) — verify correct keys before encrypting any secrets. Document which key is which in your secrets.nix file.

---

### Pitfall 3: Missing identity.pub File Prevents Local Decryption

**What goes wrong:**
After encrypting a secret for a host, you try to decrypt it locally with `agenix -d` but get "Error: No matching keys found." This happens because agenix cannot find the private key needed to decrypt, even though you encrypted with your public key. You're blocked from editing your own secrets.

**Why it happens:**
agenix looks for private keys in default SSH locations (`~/.ssh/id_rsa`, `~/.ssh/id_ed25519`, etc.). If your key has a non-standard name or location, agenix won't find it. The encryption included your public key, but decryption can't find the matching private key. Additionally, agenix does NOT use `ssh-agent`, so password-protected keys require manual entry.

**How to avoid:**
- **Keep key names standard**: Use `~/.ssh/id_ed25519` (not `~/.ssh/my-special-key.pem`)
- **Explicit key path**: Use `agenix -d -i ~/.ssh/id_rsa` to explicitly specify which private key to use
- **Verify file permissions**: Ensure private key file has `600` permissions and is readable
- **Check key format**: Ensure the key you're using matches the public key in secrets.nix
- **Document key locations**: In your project, create a `SECRETS.md` documenting which key to use for decryption
- **For password-protected keys**: Either use unprotected keys or be prepared to type the password for each operation (limitation of age/rage)

**Warning signs:**
- `agenix -d` fails with "No matching keys found" but the file is encrypted with your public key
- Password prompt appears after every secret operation (age cannot cache ssh-agent)
- Different users on same machine cannot decrypt each other's secrets

**Phase to address:**
Phase 1 (initial setup) — configure identity paths and document key handling. Add to onboarding documentation for team members.

---

### Pitfall 4: initrd Secrets Are Unavailable During Boot

**What goes wrong:**
Secrets configured for early boot (e.g., `boot.initrd.secrets`) don't decrypt properly. The secret file is copied to the initrd during build, but agenix activates *after* the initrd, so the decrypted secret doesn't exist when the initrd runs.

**Why it happens:**
agenix decrypts secrets during the activation phase via an activation script. The initrd builds before activation scripts run. If you reference an agenix secret in the initrd (e.g., for disk encryption), the secret doesn't exist when needed, breaking boot.

**How to avoid:**
- **Static secrets for initrd**: Store initrd-required secrets as static files outside `/run/agenix`, not as agenix-decrypted files
- **Two-step bootstrap**: Use `nixos-rebuild test` to run activation scripts before `nixos-rebuild switch` finishes bootloader setup
- **Alternative approach**: Use LUKS passwords from a keyfile (not agenix) for encryption
- **Document limitation**: Make clear that agenix is for runtime secrets, not boot-time secrets
- **Plan activation timing**: Order activation scripts so initrd dependencies are handled before agenix runs

**Warning signs:**
- Initrd fails to find expected secret files at boot
- `nixos-rebuild switch` succeeds but system won't boot
- Disk decryption prompts for password instead of using secret
- Activation script errors mentioning `/run/agenix` not existing during boot

**Phase to address:**
Phase 2 (boot/encryption setup) — identify which secrets must be available pre-activation and handle separately. Test boot sequence thoroughly before deploying to production.

---

### Pitfall 5: Rekeying Secrets When Adding Hosts Creates Cascading Errors

**What goes wrong:**
You add a new machine to your multi-machine setup and run `agenix --rekey` to encrypt existing secrets for the new host. The rekey succeeds, but git diffs show all secrets changed (not just the new host's keys), causing confusion. Worse, if you abort the rekey midway, secrets become partially encrypted and unreadable.

**Why it happens:**
When rekeying, agenix decrypts the old secret, then re-encrypts it with the new recipient list. The age encryption format changes even if recipients don't, creating large git diffs. If the rekey process is interrupted (network failure, crash, user cancellation), the partially-encrypted file is left in the repository, breaking all subsequent decryption.

**How to avoid:**
- **Rekey in isolation**: Always rekey with a clean working tree and no uncommitted changes
- **Commit before rekeying**: Commit current state, then do rekey in a separate commit with clear message
- **Use git to verify**: Check `git diff` after rekeying; if it shows changes beyond what you intended, revert and investigate
- **Atomic rekeying**: Don't interrupt `agenix --rekey` — let it complete fully or abort cleanly
- **Backup before rekeying**: Keep a backup of encrypted secrets before rekeying; if something goes wrong, you can restore
- **Document host keys**: Maintain a clear list of which host key corresponds to which machine; add new keys explicitly
- **Test rekey separately**: Rekey in a branch, verify decryption works on all machines, then merge
- **Consider agenix-rekey extension**: Use automated rekeying tool (agenix-rekey) for complex multi-machine setups

**Warning signs:**
- Large git diff showing all secrets changed when only one host added
- `agenix -d` fails after interrupted rekey with "corrupted" or "invalid" age format
- Different machines decrypt differently after rekeying
- Rekeying takes significantly longer than initial encryption

**Phase to address:**
Phase 3+ (multi-machine deployment) — establish clear procedures for adding hosts. Document host key procurement and rekeying process. Consider using agenix-rekey for automation.

---

### Pitfall 6: Password-Protected SSH Keys Break Automation

**What goes wrong:**
Your SSH private key is password-protected (standard security practice). When you use agenix in automation (CI/CD, deployment scripts, automated rebuilds), you get stuck at a password prompt that cannot be answered. The decryption hangs or fails silently.

**Why it happens:**
agenix (via the underlying rage tool) does not support `ssh-agent`, which would allow automatic password prompting and caching. If your key requires a passphrase, you must type it each time — impossible in automated contexts. There's no way to pipe the password or use environment variables.

**How to avoid:**
- **Separate deployment key**: Create an unencrypted SSH key specifically for deployment automation (not your personal key)
- **Encrypted storage**: Keep the deployment key encrypted in a secrets manager (HashiCorp Vault, AWS Secrets Manager) rather than as a local file
- **Use agenix for runtime only**: Handle secret generation and distribution outside automated builds; use agenix only for local development and server-side decryption
- **Pre-provision keys**: On target machines, provision the host key without password protection (it's the system's key, not user authentication)
- **CI/CD adaptation**: Design CI/CD to avoid needing to decrypt agenix secrets; use ephemeral credentials instead
- **Acknowledge the limitation**: Document that password-protected user keys don't work with agenix automation

**Warning signs:**
- `agenix` commands hang during CI/CD runs
- Deployment scripts timeout waiting for password input
- Error messages about "no matching keys" but keys should work locally
- Different behavior between local (interactive) and automated (non-interactive) runs

**Phase to address:**
Phase 2+ (automation and CI/CD) — establish clear policy on key management. Use unencrypted keys for automation only (with strong access controls), or use alternative tools that support ssh-agent.

---

### Pitfall 7: Permissions and Ownership Misconfiguration Prevents Service Access

**What goes wrong:**
A systemd service needs to read an agenix secret, but the secret is owned by `root:root` with `0400` permissions (the default). The service runs as a different user and cannot read the file, causing the service to fail at startup.

**Why it happens:**
agenix defaults to restrictive permissions (only root can read). If you forget to configure `owner` and `group` in the secret declaration, services running as non-root users cannot access the secret. This is often discovered only during deployment when the service starts.

**How to avoid:**
- **Always declare owner/group**: For every secret used by a service, explicitly set the owner and group:
  ```nix
  age.secrets.nginx-htpasswd = {
    file = ../secrets/nginx.htpasswd.age;
    owner = "nginx";
    group = "nginx";
    mode = "0600";
  };
  ```
- **Reference the path at runtime**: Services must read from the decrypted path (default `/run/agenix/secret-name`), not try to access the original encrypted file
- **Test service startup**: In a test environment, start the service and verify it can read the secret before deploying
- **Use descriptive mode names**: Use `0600` (user read/write only) or `0640` (user read/write, group read) — never `0644` (world-readable)
- **Document secret usage**: Maintain a manifest of which service uses which secret and what permissions it needs
- **Check activation order**: Ensure secret decryption happens before the service starts

**Warning signs:**
- Service fails to start with "Permission denied" errors
- Service works in interactive shell but fails under systemd
- Checking `/run/agenix/` shows files exist but service cannot access them
- Need to `sudo` to run the service manually, but systemd user doesn't have access

**Phase to address:**
Phase 2 (service configuration) — establish a checklist for secret permissions. Add unit tests that verify services can read their required secrets.

---

## Moderate Pitfalls

### Pitfall 8: Secrets Declaration Must Precede Creation

**What goes wrong:**
You create an encrypted secret file but forget to declare it in `secrets.nix`. Later, you reference it in your NixOS configuration, but agenix never decrypts it because it's not in the secrets manifest. The reference points to a non-existent path.

**Why it happens:**
agenix uses `secrets.nix` as the source of truth for which secrets exist and who can decrypt them. If a secret isn't declared there, agenix doesn't know it exists, doesn't decrypt it, and doesn't create the `/run/agenix/` entry for it.

**How to avoid:**
- **Declare first**: Always add the secret to `secrets.nix` before creating the encrypted file
- **Create via agenix**: Use `agenix -e secrets.nix` or `EDITOR=vim agenix -e secrets/secret-name.age` to ensure declaration and creation are linked
- **Checklist approach**:
  1. Edit `secrets.nix` and declare the secret with its recipients
  2. Run `agenix -e secrets/secret-name.age` to create the file
  3. Reference in NixOS config
  4. Test decryption locally

**Warning signs:**
- Secret is encrypted but configuration says "file not found"
- `agenix -d` fails but the `.age` file exists
- Secret works after re-adding to `secrets.nix` and rekeying

**Phase to address:**
Phase 1 (initial setup) — document the declaration-before-creation pattern and add to development checklist.

---

### Pitfall 9: Git Diffs Obscure Actual Secret Changes

**What goes wrong:**
You want to check what changed in a secret file, but `git diff` shows the entire encrypted content changed (as expected with encryption), making it impossible to tell if only one field was updated or the whole file was replaced. This makes code review of secret changes difficult.

**Why it happens:**
Age encryption changes the entire ciphertext if any plaintext byte changes, due to the encryption design. Git diffs cannot show meaningful line-level changes in encrypted files. If secrets are large or contain structured data, you can't tell what actually changed without decrypting locally.

**How to avoid:**
- **Decrypt locally before diffing**: Use `agenix -d -i ~/.ssh/id_ed25519 secret.age` to view the plaintext before and after
- **Small, focused secrets**: Keep secrets small and focused (one credential per file, not a YAML bundle)
- **Document changes**: When rekeying or updating, include a commit message explaining what changed
- **Use git-diff filters**: Configure `.gitattributes` to treat `.age` files specially, but recognize you still can't see encrypted diffs
- **Separate secrets from config**: Keep secrets in their own directory with a clear manifest; don't mix with other files

**Warning signs:**
- Cannot verify what changed in secrets during code review
- Large `.age` files (suggests bundled secrets that could be split)
- Confusion about whether a secret was actually modified or just re-encrypted

**Phase to address:**
Phase 1+ (workflow setup) — establish practices for managing secret changes. Document review procedures.

---

### Pitfall 10: Multi-Machine Key Lists Become Hard to Maintain

**What goes wrong:**
As you add more machines, your `secrets.nix` grows with per-machine keys. Keeping track of which secret needs which machine's key becomes error-prone. New developers don't know which key to add for a new secret, leading to incomplete or incorrect recipient lists.

**Why it happens:**
Without a clear taxonomy, `secrets.nix` becomes a flat list of keys. Adding a new machine requires identifying all secrets that need it, then rekeying each one. There's no built-in way to say "all secrets for production machines" or "all secrets for CI/CD."

**How to avoid:**
- **Organize by role**: Create semantic groups in `secrets.nix`:
  ```nix
  let
    common = [ dev_key prod_key ];
    prod_only = [ prod_key ];
    ci_only = [ ci_key ];
  in {
    "db-password.age".publicKeys = prod_only;
    "api-key.age".publicKeys = common;
    "github-token.age".publicKeys = ci_only;
  }
  ```
- **Document the matrix**: Maintain a separate document or script showing which key applies to which machine/role
- **Use consistent naming**: Name keys after their machines or roles: `centauri_host`, `nirvana_host`, `ci_deploy_key`
- **Consider agenix-rekey**: This tool automates determining which keys each secret needs
- **Version the matrix**: Keep `secrets.nix` in a structure that's easy to grep and understand

**Warning signs:**
- Cannot quickly answer "which machines decrypt secret X?"
- New team members struggle to add secrets for new machines
- Rekeying is error-prone or forgotten
- Secrets encrypted for wrong set of machines

**Phase to address:**
Phase 2+ (multi-machine expansion) — design the key organization scheme before adding second machine. Document the matrix.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use user key instead of host key | Faster local testing | Deployment fails; must redo secrets | Never — breaks deployment |
| Skip `owner`/`group` config | Quicker setup | Services can't read secrets | Never — causes runtime failures |
| Commit unencrypted secrets temporarily | "Just testing" | Credentials in git history; cannot be undone | Never — security breach |
| Use password-protected user key in CI | Follows best practices locally | Automation hangs or fails | Never for CI — use separate unencrypted key instead |
| Single bundled secrets file | Simpler to manage | Hard to rekey one secret; git diffs opaque | Acceptable for <5 secrets; split beyond that |
| Defer host key generation | Simplifies fresh install | Bootstrap fails; blocks deployment | Never — pre-generate keys before install |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| systemd services | Forgetting to set owner/group, secret unreadable | Always declare owner, group, mode for service secrets |
| nixos-rebuild switch | Running from non-root user with mismatched keys | Run as root, ensure host key available in /etc/ssh |
| CI/CD pipelines | Using password-protected SSH keys | Create separate unencrypted deployment key or use secrets manager |
| Home Manager | Forgetting home-manager module isn't included by default | Explicitly import agenix.homeManagerModules.default |
| Container deployments | Not mounting SSH key into container | Bind-mount private key or copy it during build |
| Multi-machine git repos | One shared secrets.nix with all machines' keys | Split into per-machine or per-environment files as machines grow |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Large encrypted secrets | Slow decryption, large activation logs | Keep secrets <1MB; split large configs | >5MB secrets cause noticeable slowdown |
| Rekeying many secrets manually | Operator types password 50 times | Use agenix-rekey for >10 secrets | 10+ secrets make manual rekeying impractical |
| Checking git history for secrets | Grep searches slow on large repo | Exclude .age files from full-text search | Large repos with many secrets slow down searches |
| Decryption on every rebuild | Activation takes 30+ seconds | Cache decryption or avoid unnecessary rebuilds | Not a performance issue at 1-10 secrets; becomes noticeable with 50+ |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|-----------|
| Committing unencrypted secrets to git | Permanent credential exposure in history | Use `git-crypt` or `git-secrets` pre-commit hooks; never bypass encryption |
| Sharing private SSH keys across team | Compromise affects all users | Each developer uses their own key; use CI-specific key for automation |
| Storing age private key in world-readable location | Any user on system can decrypt | Keep keys in `~/.ssh/` with `600` permissions; no world-readable secrets |
| Using same key for development and production | Compromise of dev key breaks production | Separate keys by environment; ci_key, prod_key, dev_key |
| Not rotating host keys | Long-term compromise risk | Establish rotation policy (e.g., annually); document procedure |
| Trusting age "authenticity" claims | Age doesn't authenticate; attacker can modify secrets | Treat .age files as potentially-modified; validate via other means |

---

## "Looks Done But Isn't" Checklist

- [ ] **Secret encryption**: Verified that `agenix -d -i <key>` successfully decrypts the secret locally
- [ ] **Host key setup**: Confirmed host key path in `/etc/ssh/` on target machine; tried `nixos-rebuild switch` at least once
- [ ] **Service permissions**: Checked that service user can read `/run/agenix/secret-name` after deployment
- [ ] **Multi-machine setup**: For each machine with different keys, re-keyed secrets and verified decryption on target
- [ ] **CI/CD integration**: Tested secret decryption in CI environment with actual deployment key (not personal key)
- [ ] **Boot order**: If secrets needed at boot, verified initrd doesn't depend on agenix-decrypted files
- [ ] **Key backup**: Stored copies of host keys and master keys in secure location (encrypted backups outside git)
- [ ] **Documentation**: Written down which key is which, where host keys come from, how to add new machines
- [ ] **Git history cleanup**: Verified no unencrypted secrets in git history from before setup
- [ ] **Fallback plan**: If host key is lost, documented procedure to regenerate/recover (or accepted it requires system reinstall)

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Forgot to encrypt secret with new host key | MEDIUM | Decrypt secret, add new host key to secrets.nix, re-encrypt with `agenix --rekey`, push updated file |
| Lost host SSH key, cannot decrypt secrets | HIGH | Restore from backup, or reinitialize system and rekey all secrets with new host key |
| Committed unencrypted secret to git history | HIGH | Use `git-filter-branch` or `BFG` to remove from history; rotate the compromised credential; consider key rotation |
| Service cannot read secret (permissions) | LOW | Update owner/group in configuration, run `nixos-rebuild switch` to re-decrypt with correct permissions |
| Interrupted rekey left secret corrupted | MEDIUM | Revert to previous git commit, retry rekey fully, test on all machines before re-pushing |
| Password-protected key blocks automation | MEDIUM | Generate new unencrypted deployment key, re-encrypt secrets with new key, update CI config to use new key |
| initrd secret not available at boot | HIGH | Move secret outside agenix, OR run `nixos-rebuild test` before `nixos-rebuild switch`, OR use alternative tool for boot-time secrets |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Bootstrap chicken-and-egg | Phase 0 (pre-deployment setup) | Successfully deploy fresh system without manual host key intervention |
| Host key confusion | Phase 1 (initial secrets) | Decrypt on target machine with host key; local user key alone fails to decrypt |
| Missing identity.pub | Phase 1 (initial setup) | `agenix -d -i ~/.ssh/id_rsa` succeeds without manual key path specification |
| initrd secrets unavailable | Phase 2 (boot/encryption setup) | System boots successfully; verify secrets are *not* available in initrd (expected), *are* available after activation |
| Rekeying cascading errors | Phase 3 (multi-machine) | Rekey test shows only expected key changes; all machines decrypt successfully after rekey |
| Password-protected keys break automation | Phase 2 (CI/CD setup) | Automated decryption succeeds without prompting for password; deployment key is separate and unencrypted |
| Permissions misconfiguration | Phase 2 (service setup) | Service starts successfully; verify permissions with `stat /run/agenix/secret-name` after boot |
| Declaration missing | Phase 1 (secrets workflow) | All `.age` files have corresponding entries in `secrets.nix`; checklist during code review |
| Git diffs obscured | Phase 1+ (workflow) | Document all secret changes in commit messages; maintain off-git manifest of meaningful changes |
| Multi-machine key management | Phase 2+ (multi-machine) | Key matrix document exists and is kept in sync; new machines' keys added before deployment |

---

## Phase-Specific Recommendations

### Phase 0: Pre-Deployment Setup (before first machine)
- **Pre-generate SSH host keys** for all target machines offline
- **Create unencrypted deployment key** (separate from user keys) for automation
- **Document key sources and locations** in team wiki
- **Establish secrets.nix structure** and naming conventions

### Phase 1: Initial Secrets Integration
- **Verify host key path** exists and is readable
- **Set up local decryption** with user key; test `agenix -d` locally
- **Declare before creating**: Add to secrets.nix first, then encrypt
- **Test local editing**: Ensure `EDITOR=vim agenix -e` works

### Phase 2: Service Integration & Automation
- **Configure owner/group** for every service secret
- **Test CI/CD decryption** with deployment key (not personal key)
- **Verify initrd doesn't use agenix** secrets; use static files if needed
- **Document service permissions** in project manifest

### Phase 3+: Multi-Machine Expansion
- **Plan rekeying procedure** before adding new machines
- **Establish host key discovery process** (ssh-keyscan, GitHub API, etc.)
- **Consider agenix-rekey** for automation if 10+ secrets
- **Test multi-machine decryption** on each target before committing

---

## Ragenix-Specific Notes

**ragenix** is a Rust rewrite of agenix addressing some shell script fragility, but the pitfalls above still apply. Key differences:

| Pitfall | agenix | ragenix |
|---------|--------|---------|
| Bootstrap chicken-and-egg | Exists | Exists (same underlying issue) |
| Shell script reliability | Fragile; occasional parsing bugs | More robust; better error handling |
| Password-protected keys | Doesn't work | Doesn't work (age limitation) |
| Flakes support | Yes, legacy too | Flakes only (intentional) |
| CLI parsing | Basic | More robust with validation |
| Plugin support | No | Yes (future extensibility) |
| Shell completions | No | Yes |

**Note:** Switching to ragenix doesn't eliminate pitfalls; it improves tool reliability but doesn't address operational or design issues.

---

## Sources

- [Agenix GitHub Repository - Official README](https://github.com/ryantm/agenix)
- [Agenix NixOS Wiki](https://nixos.wiki/wiki/Agenix)
- [NixOS Discourse - Bootstrap with agenix](https://discourse.nixos.org/t/bootstrap-fresh-install-using-agenix-for-secrets-management/17240)
- [Nix Secrets for Dummies - Farid Zakaria](https://fzakaria.com/2024/07/12/nix-secrets-for-dummies)
- [Getting Started with Agenix - Mitchell Hanberg](https://www.mitchellhanberg.com/getting-started-with-agenix/)
- [Managing Secrets with agenix - Jonas Carpay](https://jonascarpay.com/posts/2021-07-27-agenix.html)
- [Managing Secrets in NixOS With Agenix - Sawyer Shepherd](https://sawyershepherd.org/post/managing-secrets-in-nixos-with-agenix/)
- [Secret Management on NixOS with sops-nix (2025) - Michael Stapelberg](https://michael.stapelberg.ch/posts/2025-08-24-secret-management-with-sops-nix/)
- [Handling Secrets in NixOS: An Overview - NixOS Discourse](https://discourse.nixos.org/t/handling-secrets-in-nixos-an-overview-git-crypt-agenix-sops-nix-and-when-to-use-them/35462)
- [Comparison of Secret Managing Schemes - NixOS Wiki](https://wiki.nixos.org/wiki/Comparison_of_secret_managing_schemes)
- [ragenix GitHub Repository](https://github.com/yaxitech/ragenix)
- [agenix-rekey - Automated Rekeying Extension](https://github.com/oddlama/agenix-rekey)

---

*Pitfalls research for: NixOS secrets management with agenix/ragenix*
*Researched: 2026-02-06*
