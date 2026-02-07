# Codebase Concerns

**Analysis Date:** 2026-02-04

## Security Issues

**GitHub PAT Hardcoded in Repository:**
- Risk: Personal access token exposed in version control, accessible to anyone with repo access
- Files: `nixos/configurations.nix` (line 42-44)
- Current state: GitHub personal access token embedded in `access-tokens` setting
- Immediate action: This token must be removed and rotated immediately. GitHub will detect and invalidate it
- Mitigation: Use Nix secrets management (agenix, sops-nix) to load tokens from secure external storage
- Impact: High - token provides write access to GitHub repositories

**Disabled CPU Mitigations:**
- Risk: System vulnerable to Spectre, Meltdown, and related CPU side-channel attacks
- Files: `nixos/machines/centauri/bootloader.nix` (line 19)
- Current setting: `"mitigations=off"` kernel parameter
- Problem: Explicitly disabled for performance gains, but exposes CPU vulnerabilities
- Recommendation: Re-enable mitigations or use selective mitigation (e.g., `mitigations=auto`) unless this is a secured isolated system
- Impact: High - depends on threat model and network exposure

## Known Bugs & Issues

**Powertop Service Always Coredumps on Boot:**
- Symptoms: Service crashes immediately after boot, but configured to restart
- Files: `nixos/machines/common/powermanagement.nix` (line 12)
- Root cause: Unknown - comments indicate "always coredumps on boot"
- Current workaround: Restart policy configured (`Restart = "on-failure"`, `RestartSec = "2s"`)
- Fix approach:
  1. Debug by running `journalctl -u powertop -n 50` to see error details
  2. Check powertop version compatibility
  3. May need to patch or downgrade powertop package
- Impact: Medium - service eventually runs but adds boot delay

**Display Server Wayland Configuration Unclear:**
- Issue: Comment indicates non-standard way of enabling Wayland
- Files: `nixos/machines/common/plasma.nix` (line 23)
- Current code: `wayland.enable = true; # # TODO find a better way to enable wayland.`
- Problem: Double comment suggests temporary/experimental approach
- Fix approach: Research proper Plasma 6 + SDDM Wayland enablement pattern in nixos-hardware or nixos wiki
- Impact: Low - currently works but approach may not be maintainable

**Missing Flatpak Configuration Source:**
- Issue: No documentation on where Flatpak packages are sourced from
- Files: `nixos/machines/common/services.nix` (line 12)
- Current code: `# TODO Add your desired Flatpak packages here`
- Problem: Large list of Flatpak packages without comments explaining selection rationale
- Impact: Low - functional but lacks maintainability documentation

## Technical Debt

**Incomplete Feature: Module Exports Not Used:**
- Issue: nixosModules defined but never utilized
- Files: `outputs.nix` (lines 50-55)
- Current code: Empty `nixosModules` export with commented examples and TODO
- Problem: Architecture supports module reuse but not documented how to consume modules
- Tech debt: Suggests incomplete refactoring toward modular design
- Impact: Medium - prevents code reuse across flakes

**Incomplete Auto-Upgrade System:**
- Issue: Automatic system upgrades are entirely disabled
- Files: `nixos/machines/common/autoupgrade.nix` (lines 12-24)
- Current state: Entire `system.autoUpgrade` configuration commented out
- Reason noted in git: "autoupgrade doesn't work because of root" (commit 58bafce)
- Problem: Manual upgrades required; no timeline for fix
- Fix approach: Investigate NixOS auto-upgrade root permission handling; consider privileged service wrapper
- Impact: Medium - requires manual maintenance; system may fall behind security patches

**Non-Configurable Hardcoded Username:**
- Issue: System assumes single user "djoolz"
- Files: `nixos/users/djoolz.nix` (lines 5-6), `nixos/configurations.nix` (line 6), `nixos/machines/common/autoupgrade.nix` (line 4)
- Current code: `home.username = "djoolz"` with TODO comment "Make username configurable through specialArgs"
- Problem: Not portable to multi-user systems or different deployments
- Fix approach: Add username via specialArgs and pass through to home-manager
- Impact: Low - works for current use case but limits reusability

**Documentation Missing: Powertop Source:**
- Issue: Power management configuration lacks explanation
- Files: `nixos/machines/common/powermanagement.nix` (line 2)
- Current code: `# Something about powermanagement. FIXME source`
- Problem: Code comment indicates incomplete understanding of what was implemented
- Impact: Low - functional but difficult to maintain or debug

**Module Import Inconsistency:**
- Issue: flatpak module imports disabled in home-manager configuration
- Files: `nixos/users/djoolz.nix` (line 17)
- Current code: `# ./modules/flatpak.nix # doesn't work here for some reason`
- Problem: Module disabled without explanation or issue tracking
- Unknown: Why it "doesn't work" in this context
- Impact: Low - Flatpak works via system-level config, but suggests incomplete module design

## Fragile Areas

**Dconf Auto-Generated Configuration:**
- Files: `nixos/users/modules/dconf.nix` (generated by dconf2nix)
- Why fragile: 1038-line auto-generated file manually edited by humans
- Risk: When regenerated, manual edits lost; conflicts on GUI setting changes
- Safe modification:
  1. Keep minimal hand-edited sections
  2. Regenerate only specific sections instead of entire file
  3. Consider splitting user-critical settings into separate section
- Test coverage: None - no way to verify dconf state matches configuration

**Bluetooth Configuration Experimental:**
- Files: `nixos/machines/centauri/other-hardware.nix` (lines 9-32)
- Why fragile: Uses `Experimental = true` flag in BlueZ settings
- Issue: Experimental A2DP Sink with multiple parallel connections (from git history: "multiple parallel bluetooth connections")
- Risk: Experimental settings may break between NixOS versions
- Safe changes: Test any Bluetooth config changes in VM first; have fallback without experimental features
- Impact: Medium - audio/input devices may fail unexpectedly

**Hardcoded Hardware Paths:**
- Files: `nixos/machines/centauri/other-hardware.nix` (lines 123-124)
- Example: TrackPoint device hardcoded as "TPPS/2 IBM TrackPoint"
- Risk: Device string varies across ThinkPad models; copy-paste to different hardware will fail
- Safe changes: Document device string detection method; add hardware-specific conditionals
- Impact: Low for current machine; high if config reused

**Incomplete Virtualisation Modules:**
- Files: Multiple virtualisation configs (libvirtd, docker_rootless, podman, quickemu)
- Why fragile: Several partially configured, some disabled in active configs
- Current state in `centauri/configuration.nix`: libvirtd and quickemu are both commented out; only docker_rootless enabled
- Risk: Enabling wrong combinations may cause conflicts
- Safe changes: Document which virtualisation technologies are mutually exclusive
- Impact: Medium - enabling multiple hypervisors can corrupt system

**Long Uncommented System Package Lists:**
- Files: `nixos/machines/common/shell.nix` (lines 6-40)
- Why fragile: 35+ packages with no rationale for each inclusion
- Risk: Package removals/renames will fail silently until rebuild attempted
- Safe changes: Group by purpose, add comments explaining why each package is needed
- Impact: Low - build-time failure is visible but maintenance is tedious

## Scaling Limits

**Hardcoded Home Directory Paths:**
- Current: `/home/djoolz` is hardcoded across multiple files
- Files: `nixos/machines/common/autoupgrade.nix`, `nixos/users/modules/dconf.nix`, and likely more
- Limit: System not portable to different users or /home locations
- Scaling path: Use `config.users.users.djoolz.home` or `$HOME` environment variable instead
- Impact: Low for single-user personal system

**Two Identical Machine Configurations:**
- Files: Both `centauri` and `mirach` use nearly identical setup via shared common modules
- Scaling issue: Adding 3rd machine requires manual config; no template/pattern applied
- Better approach: Extract common base, apply variations via module parameters
- Impact: Medium - duplication increases maintenance burden for multi-machine setups

## Missing Critical Features

**No Secrets Management:**
- Problem: GitHub token hardcoded; no pattern for other secrets (API keys, passwords)
- What's needed: Implement agenix or sops-nix for encrypted secret storage
- Blocks: Anything requiring credentials (CI/CD, API integrations)
- Files: `nixos/configurations.nix` (token location shows where secrets should go)

**No Configuration Backup/Restore:**
- Problem: Dconf settings are stored in git but no way to restore from failure
- Blocks: Safe experimentation with desktop settings
- What's needed: Snapshot/restore mechanism for dconf database

**No Machine-Specific Hardware Detection:**
- Problem: Device paths and hardware configs are hardcoded
- Blocks: Using same flake config across different hardware
- What's needed: nixos-hardware integration or hardware detection script

## Test Coverage Gaps

**No Validation of NixOS Options:**
- What's not tested: Whether all enabled NixOS options are compatible
- Files: All configuration files
- Risk: Breaking combination of features (e.g., conflicting virtualisation options)
- Priority: Medium - NixOS rebuild catches most issues but validation on CI would help

**Dconf Settings Not Verified:**
- What's not tested: Whether generated dconf configuration actually applies correctly
- Files: `nixos/users/modules/dconf.nix`
- Risk: Settings silently fail to apply; user has different state than config describes
- Priority: Low - manually tested when desktop environment accessed

**Flatpak Package Availability Not Checked:**
- What's not tested: Whether all Flatpak packages in list are available and stable
- Files: `nixos/machines/common/services.nix` (lines 11-37)
- Risk: Missing or renamed packages cause system activation to fail
- Priority: Low - would be caught at build time

## Dependencies at Risk

**Powertop Service Coredump:**
- Risk: Service dependency failing on every boot (even with restart workaround)
- Impact: Increases system boot time; unclear when/if actually functional
- Workaround path: Disable entirely and use alternative power management (tlp or laptop-mode-tools)

**Auto-Upgrade Disabled Due to Root Permission Issues:**
- Risk: System falls behind on security patches if manual upgrades not performed
- Mitigation: Could use systemd ProtectHome/ProtectSystem or dedicated updater service
- Migration plan: Enable once root permission issue resolved or switch to declarative-system-update package

---

*Concerns audit: 2026-02-04*
