# Requirements: NixOS Secrets Management

**Defined:** 2026-02-06
**Core Value:** Secrets are encrypted in version control and automatically decrypted on system activation, eliminating hardcoded credentials while maintaining reproducible builds.

## v1 Requirements

### Infrastructure

- [ ] **INFRA-01**: Ragenix flake input added to flake.nix
- [ ] **INFRA-02**: Ragenix NixOS module enabled in system configuration
- [ ] **INFRA-03**: SSH service enabled on centauri (generates host keys)
- [ ] **INFRA-04**: SSH service enabled on mirach (generates host keys)
- [ ] **INFRA-05**: Secrets directory created for storing .age files

### Encryption

- [ ] **ENCRYPT-01**: GitHub PAT encrypted with centauri's host key
- [ ] **ENCRYPT-02**: GitHub PAT encrypted with mirach's host key
- [ ] **ENCRYPT-03**: Personal SSH key encrypted with centauri's host key
- [ ] **ENCRYPT-04**: Personal SSH key encrypted with mirach's host key
- [ ] **ENCRYPT-05**: Centauri→mirach SSH key pair generated and private key encrypted with centauri's host key
- [ ] **ENCRYPT-06**: All encrypted .age files committed to git repository
- [ ] **ENCRYPT-07**: Host key mapping documented for future rekeying

### Deployment

- [ ] **DEPLOY-01**: GitHub PAT configured as age.secrets on centauri
- [ ] **DEPLOY-02**: GitHub PAT configured as age.secrets on mirach
- [ ] **DEPLOY-03**: Personal SSH key configured as age.secrets on centauri with proper owner/permissions
- [ ] **DEPLOY-04**: Personal SSH key configured as age.secrets on mirach with proper owner/permissions
- [ ] **DEPLOY-05**: Centauri→mirach private key configured as age.secrets on centauri with proper owner/permissions
- [ ] **DEPLOY-06**: Centauri→mirach public key added to mirach's authorized_keys for djoolz user

### Integration

- [ ] **INTEGRATE-01**: Hardcoded GitHub PAT removed from nixos/configurations.nix
- [ ] **INTEGRATE-02**: GitHub PAT reference replaced with ragenix secret path
- [ ] **INTEGRATE-03**: Personal SSH key deployed to ~/.ssh/ on centauri
- [ ] **INTEGRATE-04**: Personal SSH key deployed to ~/.ssh/ on mirach
- [ ] **INTEGRATE-05**: Centauri→mirach key deployed to ~/.ssh/ on centauri

### Remote Access

- [ ] **REMOTE-01**: SSH connection from centauri to mirach succeeds
- [ ] **REMOTE-02**: Remote nixos-rebuild command from centauri to mirach succeeds
- [ ] **REMOTE-03**: Deployment workflow documented

## v2 Requirements

### Advanced Key Management

- **KEYROT-01**: Automated key rotation mechanism
- **KEYROT-02**: Secret expiration tracking

### Additional Secrets

- **SECRET-01**: User password hashing with ragenix
- **SECRET-02**: Additional service credentials management

## Out of Scope

| Feature | Reason |
|---------|--------|
| Automatic key rotation | Manual rotation acceptable for v1; automate later if needed |
| Multi-user secrets | Single user (djoolz) sufficient for current setup |
| Secret versioning/history | Git provides sufficient history tracking |
| Secrets in initrd | No boot-critical secrets needed; all secrets load after activation |
| CI/CD integration | No automated deployment pipeline needed yet |
| Secret backup/recovery | Git repo backup sufficient; keys stored separately already |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | Phase 1 | Pending |
| INFRA-02 | Phase 1 | Pending |
| INFRA-03 | Phase 1 | Pending |
| INFRA-04 | Phase 1 | Pending |
| INFRA-05 | Phase 1 | Pending |
| ENCRYPT-01 | Phase 2 | Pending |
| ENCRYPT-02 | Phase 2 | Pending |
| ENCRYPT-03 | Phase 2 | Pending |
| ENCRYPT-04 | Phase 2 | Pending |
| ENCRYPT-05 | Phase 2 | Pending |
| ENCRYPT-06 | Phase 2 | Pending |
| ENCRYPT-07 | Phase 2 | Pending |
| DEPLOY-01 | Phase 3 | Pending |
| DEPLOY-02 | Phase 3 | Pending |
| DEPLOY-03 | Phase 3 | Pending |
| DEPLOY-04 | Phase 3 | Pending |
| DEPLOY-05 | Phase 3 | Pending |
| DEPLOY-06 | Phase 3 | Pending |
| INTEGRATE-01 | Phase 4 | Pending |
| INTEGRATE-02 | Phase 4 | Pending |
| INTEGRATE-03 | Phase 4 | Pending |
| INTEGRATE-04 | Phase 4 | Pending |
| INTEGRATE-05 | Phase 4 | Pending |
| REMOTE-01 | Phase 4 | Pending |
| REMOTE-02 | Phase 4 | Pending |
| REMOTE-03 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 24 total
- Mapped to phases: 24
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-06*
*Last updated: 2026-02-06 after roadmap creation*
