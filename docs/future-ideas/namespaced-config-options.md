# Namespaced repo config options

Status: future idea, not current policy.

## Goal

Explore a repo-owned option layer for machine setup so host configs can express
higher-level intent instead of repeating low-level NixOS and Home Manager
settings.

Examples discussed:

```nix
my.security = {
  apparmor = true;
  firewall = true;
  auditd = "light";
  earlyoom = true;
};

my.remoteAccess = {
  mode = "tailscale-only";
  vscodeRemote = true;
};
```

## Why this may help

- cleaner host setup for new hardware
- shared defaults for common machine classes
- repo policy can live in one place
- easier cross-module coordination and assertions
- machine configs can describe intent more clearly

## Current thoughts

- `my.*` currently feels better than `site.*` for the public namespace
- multiple namespaces may be better than one giant tree
- likely split:
  - `my.*` for public repo-facing machine options
  - `profiles.*` for reusable preset bundles/default catalogs
  - `_internal.*` for module markers and guard-rail plumbing
- profiles should set defaults for capabilities, not become opaque role magic
- capability-oriented design should stay preferred over broad role modules

## Candidate direction

Possible layering:

1. upstream NixOS/Home Manager options for final implementation
2. repo capability options under `my.*`
3. optional higher-level presets under `profiles.*`

Possible examples:

```nix
my.profile = "workstation";
my.tailscale.enableSSH = true;
my.security.auditd = "light";

profiles.workstation.security = {
  apparmor = true;
  firewall = true;
  auditd = "light";
  earlyoom = true;
};
```

## Open questions

- should `my.profile` activate exactly one preset, or should hosts compose a
  list of presets?
- which features deserve repo-owned options vs direct upstream config?
- should existing `my.autoUpdate` and `my.tailscale` stay where they are or be
  reorganized?
- what naming/style rules keep the option tree readable?
- how much policy should a profile be allowed to imply implicitly?
- where should internal markers live if they should not share the public
  namespace?

## Early guard rails

- do not wrap all upstream options 1:1
- prefer intent-oriented options over implementation details
- keep machine files readable without digging through many modules
- use assertions for invalid combinations
- avoid reintroducing broad hidden machine-role abstractions

## Good first follow-up when revisiting

- inventory repeated host configuration patterns
- define a small style guide for repo-owned options
- pick one pilot area, likely remote access or security baseline
- test whether profile defaults stay understandable in machine files
