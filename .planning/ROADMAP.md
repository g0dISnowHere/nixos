# Roadmap: NixOS Secrets Management

## Overview

Transform hardcoded GitHub tokens into encrypted secrets by integrating ragenix, encrypting credentials with machine host keys, configuring automatic decryption on system activation, and enabling secure remote deployment from centauri to mirach — delivering reproducible builds without exposed credentials.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Ragenix integration and SSH infrastructure
- [ ] **Phase 2: Secret Encryption** - Create and encrypt all credentials
- [ ] **Phase 3: Deployment Configuration** - Configure secrets in NixOS modules
- [ ] **Phase 4: Integration and Verification** - Replace hardcoded secrets and verify deployment

## Phase Details

### Phase 1: Foundation
**Goal**: Ragenix integrated into flake and SSH services enabled on both machines to generate host keys for encryption.

**Depends on**: Nothing (first phase)

**Requirements**: INFRA-01, INFRA-02, INFRA-03, INFRA-04, INFRA-05

**Success Criteria** (what must be TRUE):
  1. Ragenix flake input appears in flake.nix and NixOS module is available
  2. SSH service runs on centauri with host keys present in /etc/ssh/
  3. SSH service runs on mirach with host keys present in /etc/ssh/
  4. Secrets directory exists in repository for storing .age files

**Plans**: TBD

Plans:
- [ ] 01-01: TBD

### Phase 2: Secret Encryption
**Goal**: All secrets encrypted with appropriate host keys and committed to repository in encrypted form.

**Depends on**: Phase 1 (requires host keys from SSH services)

**Requirements**: ENCRYPT-01, ENCRYPT-02, ENCRYPT-03, ENCRYPT-04, ENCRYPT-05, ENCRYPT-06, ENCRYPT-07

**Success Criteria** (what must be TRUE):
  1. GitHub PAT exists as encrypted .age file for both centauri and mirach
  2. Personal SSH key exists as encrypted .age file for both machines
  3. Centauri→mirach SSH key pair exists with private key encrypted for centauri only
  4. All encrypted .age files are committed to git repository
  5. Host key mapping is documented for future rekeying operations

**Plans**: TBD

Plans:
- [ ] 02-01: TBD

### Phase 3: Deployment Configuration
**Goal**: Secrets configured in NixOS with proper ownership, permissions, and deployment paths.

**Depends on**: Phase 2 (requires encrypted secrets to reference)

**Requirements**: DEPLOY-01, DEPLOY-02, DEPLOY-03, DEPLOY-04, DEPLOY-05, DEPLOY-06

**Success Criteria** (what must be TRUE):
  1. GitHub PAT configured as age.secrets on both machines
  2. Personal SSH key configured as age.secrets on both machines with djoolz ownership
  3. Centauri→mirach private key configured as age.secrets on centauri with djoolz ownership
  4. Mirach's authorized_keys includes centauri→mirach public key for djoolz user
  5. Secret files have correct permissions (0600 for private keys)

**Plans**: TBD

Plans:
- [ ] 03-01: TBD

### Phase 4: Integration and Verification
**Goal**: Hardcoded credentials removed from version control and remote deployment verified working from centauri to mirach.

**Depends on**: Phase 3 (requires configured secrets)

**Requirements**: INTEGRATE-01, INTEGRATE-02, INTEGRATE-03, INTEGRATE-04, INTEGRATE-05, REMOTE-01, REMOTE-02, REMOTE-03

**Success Criteria** (what must be TRUE):
  1. Hardcoded GitHub PAT removed from nixos/configurations.nix
  2. GitHub PAT reference in configurations.nix points to ragenix secret path
  3. SSH keys are deployed to ~/.ssh/ on both machines after system activation
  4. SSH connection from centauri to mirach succeeds using deployed key
  5. Remote nixos-rebuild command from centauri to mirach completes successfully
  6. Deployment workflow is documented for future reference

**Plans**: TBD

Plans:
- [ ] 04-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/? | Not started | - |
| 2. Secret Encryption | 0/? | Not started | - |
| 3. Deployment Configuration | 0/? | Not started | - |
| 4. Integration and Verification | 0/? | Not started | - |

---
*Roadmap created: 2026-02-06*
*Last updated: 2026-02-06 after initial creation*
