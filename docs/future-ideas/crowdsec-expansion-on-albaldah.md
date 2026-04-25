# Future Idea: CrowdSec Expansion On Albaldah

This note tracks the not-yet-implemented CrowdSec follow-up work for the
`albaldah` VPS.

It is not the canonical operator guide. Use
[docs/vps/crowdsec-on-albaldah.md](../vps/crowdsec-on-albaldah.md) for the
current deployed design.

## Current Baseline

What is already in place:

- CrowdSec engine
- local API (LAPI)
- firewall bouncer
- CrowdSec Console enrollment
- CTI API key wiring
- CAPI registration
- installed collections for Linux, Traefik, Nextcloud, Authentik, HTTP CVE,
  and AppSec support

What is still functionally incomplete:

- only SSH acquisition is wired today
- Traefik logs are not yet acquired
- Nextcloud logs are not yet acquired
- Authentik logs are not yet acquired
- Docker datasource is not yet wired
- AppSec is not yet integrated into the active Traefik path

## Goal

Make LAPI on `albaldah` do as much useful work as possible without turning the
host into a high-maintenance special case.

That means:

- more high-signal acquisitions
- more useful alerts reaching LAPI
- more justified remediation decisions
- more reuse of the same LAPI by multiple remediation components

## Candidate Follow-Up Work

### 1. Wire Real Acquisitions

Add acquisitions for:

- Traefik access logs
- Nextcloud application logs
- Authentik logs
- selected Docker container logs

This is the highest-value next step because installed collections are not
useful without matching log sources.

### 2. Add Traefik-Facing Remediation

Keep firewall remediation, but add a second enforcement point at the reverse
proxy layer:

- Traefik bouncer
- or AppSec component behind Traefik

This would let LAPI decisions be enforced both at the host firewall and at the
HTTP entrypoint.

### 3. Turn AppSec From Installed Content Into Active Protection

The current module installs AppSec-related collections, but the request path is
not yet wired.

Future work:

- enable CrowdSec AppSec component
- connect Traefik to the AppSec listener
- keep the Nextcloud exclusion plugin active to reduce false positives

### 4. Add More Deliberate Profiles

The current remediation flow is still close to defaults.

Possible follow-ups:

- longer ban durations for high-confidence alerts
- different treatment for `Ip` versus `Range`
- service-aware remediation rules
- explicit postoverflow whitelists for trusted admin IPs or Tailscale ranges

### 5. Split Acquisitions By Service Ownership

If the service set grows, keep acquisitions organized by exposed service rather
than by one large mixed block.

Possible shape:

- shared CrowdSec capability module stays generic
- service-specific acquisition fragments stay near the owning service module or
  host-local area when tightly coupled

## Safety Constraints

Any expansion should keep these rules:

- do not add noisy acquisitions without validating signal quality
- do not enable aggressive remediation before whitelisting trusted operator
  paths where needed
- keep secret-backed credentials out of the Nix store
- prefer focused, explicit acquisitions over "monitor everything" sprawl

## Likely Next Implementation Order

1. Traefik acquisition
2. Authentik acquisition
3. Nextcloud acquisition
4. Docker datasource for selected containers
5. Traefik AppSec integration
6. profile tuning and whitelists

## Exit Criteria

This note can be retired once:

- the main exposed services have real acquisitions
- LAPI receives meaningful web and auth alerts beyond SSH
- at least one additional remediation path beyond nftables is active
- the stable design is documented in `docs/vps/crowdsec-on-albaldah.md`
