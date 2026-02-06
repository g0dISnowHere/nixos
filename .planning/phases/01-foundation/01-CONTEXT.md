# Phase 1: Foundation - Context

**Gathered:** 2026-02-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Integrating `ragenix` into the NixOS configuration to manage the first secret (a GitHub PAT), replacing the hardcoded value. This includes creating a secure and automated workflow for encrypting new secrets.

</domain>

<decisions>
## Implementation Decisions

### Secret Management
- **Naming Convention:** Secrets will follow a `scope/secret_name` format (e.g., `personal/github_pat`).
- **Host Key Bootstrap:** Host keys will be pre-generated as a manual, one-time setup step.
- **Secret Permissions:** Decrypted secrets needed by the user will be owned by the user (`djoolz`).
- **Encryption Workflow:** An automated helper script (`encrypt-secret.sh`) will be created. It will securely prompt for the secret value and handle the `ragenix` encryption process.

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-02-06*
