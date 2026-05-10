# Future Idea: Albaldah Security Tooling

This note tracks possible security tooling additions for the `albaldah` VPS
beyond the current CrowdSec baseline.

It is not canonical policy. The current deployed CrowdSec design is documented
in [docs/vps/crowdsec-on-albaldah.md](../vps/crowdsec-on-albaldah.md).

## Current Baseline

Today `albaldah` already has:

- CrowdSec engine
- local API (LAPI)
- firewall bouncer
- Console enrollment
- CTI API key support
- CAPI/community blocklist participation

That gives the VPS perimeter-oriented detection and remediation, but it does
not fully cover host integrity, runtime behavior, or compliance-style auditing.

## Candidate Additions

### Lynis

Use for:

- periodic host security audits
- hardening review after rebuilds
- low-friction operator checks

Why it is a good fit:

- low operational weight
- useful for Unix/NixOS hardening gaps
- complements CrowdSec instead of overlapping heavily with it

### AIDE

Use for:

- file integrity monitoring
- detecting unexpected changes in critical system paths

Good targets:

- `/etc`
- important service configs
- selected binaries
- web-exposed application config

### Falco

Use for:

- runtime threat detection on the host
- syscall-level detection for containers
- suspicious process and container behavior

Why it is attractive here:

- `albaldah` runs exposed services and Docker workloads
- Falco covers behavior that CrowdSec log-based detections may miss

### auditd

Use for:

- kernel audit trail
- execution and file access auditing
- compliance-oriented event capture

Tradeoff:

- powerful, but easy to make noisy
- best added only with a narrow, deliberate rule set

### OpenSCAP

Use for:

- compliance and baseline scanning
- policy-oriented security validation

This is lower priority than Lynis unless compliance reporting becomes a real
need.

### Wazuh

Use for:

- centralized SIEM/XDR
- file integrity monitoring
- vulnerability detection
- broader security analytics

Tradeoff:

- much heavier than the rest
- likely overkill for a single VPS unless the repo grows into a larger managed
  fleet security platform

## Suggested Priority

If the goal is maximum practical value with minimal operational drag:

1. Lynis
2. AIDE
3. Falco
4. auditd
5. OpenSCAP
6. Wazuh

## Design Constraints

Any addition should preserve these rules:

- avoid overlapping tools without a clear role split
- prefer low-noise defaults first
- keep host-specific security policy explicit
- do not turn `albaldah` into a one-off security snowflake

## Possible End State

A balanced future stack for `albaldah` could be:

- CrowdSec for external attack detection and remediation
- Lynis for periodic host auditing
- AIDE for file integrity
- Falco for runtime/container detection

That would expand visibility meaningfully without immediately committing to a
full SIEM/XDR platform.
