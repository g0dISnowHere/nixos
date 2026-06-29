Additional suggestions beyond the namespace discussion

Based on the full repo analysis, here are actionable improvements:

### 1. Consolidate SSH configuration (Quick win)

You have ssh.nix and ssh-server.nix in modules/nixos/services/, but they're doing minimal work. Also, you have tailscale-client.nix  
and tailscale-router.nix that are basically empty wrappers.

Current state:
- ssh.nix - basic openssh config
- ssh-server.nix - just imports ssh.nix + enables firewall
- tailscale-client.nix - sets acceptRoutes = true by default
- tailscale-router.nix - completely empty preset

Recommendation: Collapse these into the base modules they wrap. The "client vs router" distinction doesn't add value—it's already
expressed in my.tailscale.* options.

```nix
# Just use modules/nixos/services/tailscale.nix everywhere                                                                         
# Delete tailscale-client.nix and tailscale-router.nix                                                                             
```

Same for SSH—you don't need ssh-server.nix as a separate file. Just import ssh.nix directly.

### 2. Fix the security TODOs (Safety-critical)

```nix
"mitigations=off" # FIXME dangerous.                                                                                               
```

This appears on both centauri and mirach. Either:
- Remove it if you don't need the performance
- Document why it's acceptable for these machines specifically
- Add it as a my.performance.disableCpuMitigations option with big warnings

Don't leave "FIXME dangerous" in production configs.

### 3. Make desktopEnvironment less magical (Architecture improvement)

Right now mkNixosSystem automatically imports desktop modules:

```nix
desktopEnvironmentModule = if desktopEnvironment != null then                                                                      
    ../modules/nixos/desktop/${desktopEnvironment}.nix                                                                               
```

This violates your "explicit imports" principle. The machine definition hides that GNOME is being loaded.

Better approach: Make it explicit in the flake machine definitions:

```nix
centauri = self.lib.mkNixosSystem {                                                                                                
    system = "x86_64-linux";                                                                                                         
    hostname = "centauri";                                                                                                           
    enableHomeManager = true;                                                                                                        
    modules = [                                                                                                                      
    ../../modules/nixos/desktop/gnome.nix  # explicit!                                                                             
    ../../modules/nixos/system/base.nix                                                                                            
    # ...                                                                                                                          
    ];                                                                                                                               
};                                                                                                                                 
```

Drop the desktopEnvironment parameter entirely. One less magic behavior.

### 4. Standardize the Home Manager pattern (Consistency)

Only centauri and mirach have Home Manager integration, and they use identical boilerplate:

```nix
home-manager.users.djoolz = {                                                                                                      
    imports = [ ../../../flake/homes/users/djoolz/workstation.nix ];                                                                 
    home.stateVersion = "25.11";                                                                                                     
};                                                                                                                                 
```

Option A: Extract to a module:

```nix
# modules/nixos/users/djoolz-workstation.nix                                                                                       
{ config, lib, ... }: {                                                                                                            
    options.my.users.djoolz.enableWorkstation = lib.mkEnableOption "...";                                                            
                                                                                                                                    
    config = lib.mkIf config.my.users.djoolz.enableWorkstation {                                                                     
    home-manager.users.djoolz = {                                                                                                  
        imports = [ ../../../flake/homes/users/djoolz/workstation.nix ];                                                             
        home.stateVersion = "25.11";                                                                                                 
    };                                                                                                                             
    };                                                                                                                               
}                                                                                                                                  
```

Option B: Handle it in mkNixosSystem:

```nix
mkNixosSystem = {                                                                                                                  
    homeManagerProfile ? null,  # "workstation" | "minimal" | null                                                                   
    ...                                                                                                                              
}                                                                                                                                  
```

Either way, eliminate the repetition.

### 5. Document or delete the future-ideas backlog (Maintenance hygiene)

You have 17 future-ideas docs. Some look stale. Go through and:
- Move active ones you're actually considering to a docs/proposals/ directory with status tags
- Archive the rest to docs/archive/abandoned-ideas/
- Keep future-ideas/ for only short-term (< 3 month horizon) ideas

Right now it's hard to tell what's serious vs what's a brain dump from months ago.

### 6. Create a machine decision tree (Operator UX)

When you DO add a new machine, you currently have to:
1. Look at existing machines
2. Guess which modules to import
3. Figure out which my.* options exist

Add docs/reference/new-machine-checklist.md:

```markdown
# New Machine Setup Checklist                                                                                                      
                                                                                                                                    
## 1. Create machine directory                                                                                                     
- [ ] nixos/machines/<hostname>/default.nix                                                                                        
- [ ] nixos/machines/<hostname>/hardware-configuration.nix                                                                         
- [ ] nixos/machines/<hostname>/firewall.nix (if needed)                                                                           
                                                                                                                                    
## 2. Choose base modules                                                                                                          
- [ ] modules/nixos/system/base.nix (always)                                                                                       
- [ ] Desktop? modules/nixos/desktop/{gnome,plasma,niri}.nix                                                                       
- [ ] Virtualization? modules/nixos/virtualisation/{docker,libvirtd}.nix                                                           
                                                                                                                                    
## 3. Configure my.* options                                                                                                       
- [ ] my.tailscale.enableSSH = true/false                                                                                          
- [ ] my.autoUpdate.enable = true/false                                                                                            
- [ ] my.autoUpdate.mode = "consumer" | "updater"                                                                                  
                                                                                                                                    
## 4. Add to flake                                                                                                                 
- [ ] flake/machines/{workstations,servers}.nix                                                                                    
                                                                                                                                    
## 5. Validate                                                                                                                     
- [ ] nix eval .#nixosConfigurations.<hostname>.config.system.build.toplevel                                                       
- [ ] sh validate.sh                                                                                                               
```

### 7. Unify firewall configuration (My Priority 1 from earlier)

Implement this as a concrete example of a good my.* option:

```nix
# modules/nixos/observability/prometheus-firewall.nix                                                                              
{ config, lib, ... }:                                                                                                              
let cfg = config.my.observability;                                                                                                 
in {                                                                                                                               
    options.my.observability.allowPrometheusFromDocker = lib.mkEnableOption                                                          
    "Allow Prometheus scraping from Docker bridges to host exporters";                                                             
                                                                                                                                    
    config = lib.mkIf cfg.allowPrometheusFromDocker {                                                                                
    networking.firewall = {                                                                                                        
        interfaces.tailscale0.allowedTCPPorts = [ 9100 9558 ];                                                                       
        extraInputRules = ''                                                                                                         
        iifname { "docker0", "br-*" } tcp dport { 9100, 9558 } accept comment "Docker->host Prometheus"                            
        '';                                                                                                                          
    };                                                                                                                             
    };                                                                                                                               
}                                                                                                                                  
```

Then machines just use:

```nix
my.observability.allowPrometheusFromDocker = true;                                                                                 
```

Delete the three identical firewall.nix files.

### 8. Explicit stateVersion handling (Reduce boilerplate)

All machines have the same pattern:

```nix
# Do not change casually. See docs/architecture/state-version-reasons.md.                                                          
system.stateVersion = "25.11";                                                                                                     
```

Move this to mkNixosSystem:

```nix
mkNixosSystem = { initialStateVersion ? "25.11", ... }: {                                                                          
    # ...                                                                                                                            
    system.stateVersion = lib.mkDefault initialStateVersion;                                                                         
}                                                                                                                                  
```

Then machines inherit it automatically, and you only override when actually deploying an older machine.

### 9. Audit your flatpak module split (Questionable abstraction)

You have 6 flatpak modules (browsers, creative, development, media, messaging, productivity) that are just package lists:

```nix
_: {                                                                                                                               
    services.flatpak.packages = [ "org.mozilla.firefox" "com.vivaldi.Vivaldi" ];                                                     
}                                                                                                                                  
```

This feels over-modularized. Consider:
- Collapse into one flatpak-packages.nix with options for categories
- Or move entirely to Home Manager (user-level apps)
- Or keep machine-specific package lists in machine files

Right now you're importing 6 modules just to declare a dozen packages. That's more files than it's worth.

### 10. Update the architecture docs with your current model (Documentation debt)

docs/architecture/capability-modules.md describes your model, but:
- It doesn't mention my.* options at all
- It doesn't explain the flake machine factory pattern
- It doesn't cover the current split between flake layer vs machine layer vs module layer

Write docs/architecture/configuration-layers.md explaining:

```
Layer 1: flake/machines/*.nix                                                                                                      
    - mkNixosSystem calls with explicit module lists                                                                                 
    - Machine identity and high-level structure                                                                                      
                                                                                                                                    
Layer 2: nixos/machines/<hostname>/*.nix                                                                                           
    - Hardware-specific config                                                                                                       
    - Machine-specific overrides                                                                                                     
    - Local coordination (firewall rules, etc.)                                                                                      
                                                                                                                                    
Layer 3: modules/nixos/*/*.nix                                                                                                     
    - Reusable capability modules                                                                                                    
    - my.* coordination options                                                                                                      
    - Upstream NixOS wiring                                                                                                          
                                                                                                                                    
Layer 4: flake/homes/*                                                                                                             
    - User-level Home Manager profiles                                                                                               
    - Portable across machines and standalone HM                                                                                     
```

Priority ranking

If I had to pick 3 to do now:

1. #7 - Unify firewall config - Eliminates actual duplication, demonstrates good my.* option design
2. #2 - Fix security TODOs - "FIXME dangerous" shouldn't ship
3. #10 - Document configuration layers - Makes your current (good!) design explicit

The namespace proposal is not in this list because you already have the good parts of it.

11. Centralize allowUnfree (Reduce repetition)

You set config.allowUnfree = true in 5 places in flake/lib.nix:
- Main nixpkgs
- pkgs-unstable (twice - once for HM, once for NixOS)
- pkgs-tailscale
- pkgs-zellij

Extract this:

```nix
let                                                                                                                                
    mkPkgs = nixpkgs: system: import nixpkgs {                                                                                       
    inherit system;                                                                                                                
    config.allowUnfree = true;                                                                                                     
    };                                                                                                                               
in {                                                                                                                               
    # Then use mkPkgs everywhere                                                                                                     
    pkgs-unstable = mkPkgs nixpkgs-unstable system;                                                                                  
    pkgs-tailscale = mkPkgs nixpkgs-broken system;                                                                                   
    pkgs-zellij = mkPkgs nixpkgs-zellij system;                                                                                      
}                                                                                                                                  
```

12. Rethink the pkgs- overlay strategy* (Architecture smell)

You're maintaining 4 separate nixpkgs pins:
- nixpkgs (main)
- nixpkgs-unstable (for newer packages)
- nixpkgs-broken (for tailscale? the name is concerning)
- nixpkgs-zellij (for one package?)

Questions:
- Why does tailscale need its own nixpkgs pin named "broken"?
- Why does zellij need its own pin instead of using unstable?
- Are these pins actively maintained or frozen at old commits?

Recommendation: Audit which packages actually need non-main pins and why. Document it. Consider using overlays instead of multiple
full nixpkgs evaluations.

13. Make monitoring-inventory.nix more useful (Leverage existing structure)

You have a great inventory structure in monitoring-inventory.nix that describes machine roles, capabilities, and exposure tiers. But
it's only used for:

```nix
inherit monitoringInventory;                                                                                                       
monitoringInventoryJson = builtins.toJSON monitoringInventory;                                                                     
```

Leverage it more:

```nix
# In mkNixosSystem                                                                                                                 
mkNixosSystem = { hostname, ... }:                                                                                                 
let                                                                                                                                
    hostMeta = monitoringInventory.hosts.${hostname} or null;                                                                        
in {                                                                                                                               
    # Use inventory to auto-configure monitoring                                                                                     
    assertions = [                                                                                                                   
    {                                                                                                                              
        assertion = hostMeta != null -> hostMeta.monitoring_enabled;                                                                 
        message = "${hostname} not found in monitoring inventory";                                                                   
    }                                                                                                                              
    ];                                                                                                                               
                                                                                                                                    
    # Auto-tag machines for Prometheus service discovery                                                                             
    environment.etc."machine-metadata.json".text = builtins.toJSON hostMeta;                                                         
}                                                                                                                                  
```

This makes the inventory a source of truth instead of just documentation.

14. Consolidate the flatpak module structure (Cleanup)

Current structure:

```
modules/nixos/services/flatpak.nix  # Infrastructure                                                                               
modules/nixos/flatpak/*.nix         # 6 tiny package lists                                                                         
```

Each machine imports flatpak.nix + several package modules. This is verbose for little gain.

Option A - Single module with options:

```nix
# modules/nixos/flatpak.nix                                                                                                        
my.flatpak = {                                                                                                                     
    enable = lib.mkEnableOption "Flatpak infrastructure";                                                                            
    browsers.enable = lib.mkEnableOption "Browser applications";                                                                     
    creative.enable = lib.mkEnableOption "Creative tools";                                                                           
    development.enable = lib.mkEnableOption "Development tools";                                                                     
    # ...                                                                                                                            
};                                                                                                                                 
```

Option B - Move to Home Manager:
Flatpaks are user-level apps. Why are they in NixOS modules at all? Move them to modules/home/programs/flatpak-*.nix so they travel  
with the user profile.

Option C - Keep machine-specific:
Just list flatpaks directly in machine configs. They're not really reusable across machines anyway (workstation vs server have
different needs).

15. Separate concern: pkgs-unstable in modules vs specialArgs (Consistency issue)

Some modules receive pkgs-unstable as a parameter:

```nix
{ pkgs, pkgs-unstable, ... }: {                                                                                                    
    environment.systemPackages = [ pkgs-unstable.devenv ];                                                                           
}                                                                                                                                  
```

This creates a hidden dependency on specialArgs being set correctly by mkNixosSystem. If someone imports the module elsewhere, it
breaks.

Better pattern:

```nix
{ pkgs, ... }: {                                                                                                                   
    environment.systemPackages = [ pkgs.unstable.devenv ];                                                                           
}                                                                                                                                  
```

Use overlays to make pkgs.unstable available everywhere, not specialArgs.

16. Document the multiple nixpkgs pins (Knowledge capture)

Add docs/reference/nixpkgs-pins.md:

```markdown
# Nixpkgs Pins                                                                                                                     
                                                                                                                                    
We use multiple nixpkgs versions:                                                                                                  
                                                                                                                                    
- **nixpkgs** (main): <date>, used for core system                                                                                 
- **nixpkgs-unstable**: <date>, used for: devenv, gh, vscode, crowdsec, AI tools                                                   
- **nixpkgs-broken**: <date>, used for: tailscale (reason: ...)                                                                    
- **nixpkgs-zellij**: <date>, used for: zellij (reason: ...)                                                                       
                                                                                                                                    
## Update schedule                                                                                                                 
- Main: follows NixOS release channel                                                                                              
- Unstable: updated monthly                                                                                                        
- Broken/zellij: updated only when needed                                                                                          
                                                                                                                                    
## Rationale                                                                                                                       
[Why we can't use just main + unstable]                                                                                            
```

This prevents future confusion about why these exist.

17. Standardize the enableHomeManager pattern (Implementation detail)

Only 2 machines use enableHomeManager = true (centauri, mirach). Albaldah and alhena don't. Is this intentional?

If some machines will never need Home Manager, the current approach is fine. But if you expect to add it later, consider:

```nix
# In machine files, make it explicit why HM is disabled                                                                            
# albaldah/default.nix                                                                                                             
# Home Manager: Not enabled (headless server, no user environment needed)                                                          
```

Document the decision, not just the current state.

18. Extract common "base server" and "base workstation" bundles (Middle ground)

You rejected broad role modules, but you could have transparent preset lists:

```nix
# modules/nixos/presets/base-server.nix                                                                                            
{ ... }: {                                                                                                                         
    imports = [                                                                                                                      
    ../system/base.nix                                                                                                             
    ../services/monitoring-baseline.nix                                                                                            
    ../services/vscode-remote.nix                                                                                                  
    ../services/tailscale-client.nix                                                                                               
    ];                                                                                                                               
}                                                                                                                                  
                                                                                                                                    
# modules/nixos/presets/base-workstation.nix                                                                                       
{ ... }: {                                                                                                                         
    imports = [                                                                                                                      
    ../system/base.nix                                                                                                             
    ../system/powermanagement.nix                                                                                                  
    ../services/monitoring-baseline.nix                                                                                            
    ../services/tailscale-client.nix                                                                                               
    ];                                                                                                                               
}                                                                                                                                  
```

Then machine definitions become:

```nix
imports = [                                                                                                                        
    ../../modules/nixos/presets/base-workstation.nix                                                                                 
    ../../modules/nixos/desktop/gnome.nix                                                                                            
    ../../modules/nixos/virtualisation/docker.nix                                                                                    
];                                                                                                                                 
```

This is not hiding behavior—it's just reducing import list length. The preset file is one click away and shows exactly what's
included.

19. Consider dropping tailscale-client/router wrappers entirely (Simplification)

```nix
# tailscale-client.nix                                                                                                             
{ lib, ... }: {                                                                                                                    
    imports = [ ./tailscale.nix ];                                                                                                   
    my.tailscale = {                                                                                                                 
    enableSSH = lib.mkDefault false;                                                                                               
    acceptRoutes = lib.mkDefault true;                                                                                             
    };                                                                                                                               
}                                                                                                                                  
                                                                                                                                    
# tailscale-router.nix                                                                                                             
{ ... }: {                                                                                                                         
    imports = [ ./tailscale.nix ];                                                                                                   
    my.tailscale = { };                                                                                                              
}                                                                                                                                  
```

These add almost no value. Just import tailscale.nix directly and set the options in machine files. It's clearer what's happening.

20. Add flake.nix comments explaining the structure (Onboarding)

Your outputs.nix imports are well-organized but undocumented:

```nix
imports = [                                                                                                                        
    # What goes in parts/ vs flake/?                                                                                                 
    # Why are homes separate from machines?                                                                                          
    # When do I add a new import here?                                                                                               
];                                                                                                                                 
```

Add inline comments explaining the organization:

```nix
imports = [                                                                                                                        
    # Per-system tooling (formatters, checks, dev shells)                                                                            
    ./parts/formatter.nix                                                                                                            
    ./parts/checks.nix                                                                                                               
                                                                                                                                    
    # Shared library functions (mkNixosSystem, secrets rendering)                                                                    
    ./flake/lib.nix                                                                                                                  
                                                                                                                                    
    # Machine definitions (split by role for clarity)                                                                                
    ./flake/machines/workstations.nix  # centauri                                                                                    
    ./flake/machines/servers.nix       # mirach, albaldah, alhena                                                                    
                                                                                                                                    
    # Standalone Home Manager configs (for non-NixOS hosts)                                                                          
    ./flake/homes/djoolz.nix                                                                                                         
];                                                                                                                                 
```

Priority ranking for these 10

If I had to pick the top 3:

1. #12 - Audit pkgs- pins* - The "nixpkgs-broken" name is a red flag; understand what's actually happening
2. #13 - Leverage monitoring-inventory.nix - You built good structure, now use it
3. #19 - Drop tailscale wrappers - Simplify without losing functionality  

# Namespace and Architecture Review

Date: 2026-06-08
Context: Review of `docs/future-ideas/namespaced-config-options.md` proposal and broader architecture patterns

## Summary

The proposed namespace design in `namespaced-config-options.md` is **not needed** because the repo already implements the valuable parts of it. Current architecture is working well with targeted improvements better than a full namespace layer.

## Key Findings

### 1. You already have a working namespace pattern

**Current implementation:**
- `my.tailscale.*` - 4 options for cross-module Tailscale coordination
- `my.autoUpdate.*` - 9 options for fleet update policy
- `my.virtualisation.docker.*` - exists but not actively used
- `mkNixosSystem` factory with `desktopEnvironment`, `enableHomeManager`, explicit module lists

**Verdict:** This is already the namespace design, just applied surgically where it helps.

### 2. Machine count doesn't justify broad abstraction

**Fleet inventory:**
- 4 machines total (centauri, mirach, albaldah, alhena)
- No new machines added in last 6 months
- Machines are 40% similar at best (divergent hardware, roles, needs)

**Verdict:** Not enough repetition to justify wrapper overhead.

### 3. Actual pain points identified

**Real duplication:**
1. Firewall config (Prometheus + Docker bridge rules) - **identical** on centauri/mirach
2. Home Manager boilerplate - identical on centauri/mirach
3. pkgs-unstable imported 5x with allowUnfree each time

**Not duplication (correctly divergent):**
- Boot config (different hardware)
- users.extraGroups (different per-machine needs)
- Module import lists (machines have different capabilities)

### 4. Monitoring inventory is underutilized

`flake/monitoring-inventory.nix` has rich machine metadata:
- host_role, exposure_tier, capabilities, service_roles
- Currently only exported as JSON
- **Opportunity:** Use as source of truth for auto-configuration

## Agreed-Upon Changes

### High Priority

#### 1. Extract common firewall patterns
```nix
# New: modules/nixos/observability/prometheus-firewall.nix
my.observability.allowPrometheusFromDocker = lib.mkEnableOption "...";

# Replaces identical firewall.nix in centauri/ and mirach/
```

#### 2. Add my.remoteAccess.mode option
Cross-module coordination for SSH + Tailscale + firewall:
```nix
my.remoteAccess.mode = "tailscale-only" | "public-ssh" | "none";
```

#### 3. Document the configuration layers
New file: `docs/architecture/configuration-layers.md`
- Explain the 4-layer model (flake → machine → modules → homes)
- Document when to use `my.*` options vs direct config
- Make the current (good) design explicit

### Medium Priority

#### 4. Centralize allowUnfree
Extract repetitive `config.allowUnfree = true` to helper function

#### 5. Drop tailscale-client.nix and tailscale-router.nix wrappers
They add minimal value; just import tailscale.nix directly

#### 6. Consolidate flatpak module structure
6 tiny modules (browsers.nix, creative.nix, etc.) feels over-modularized
- Option A: Single module with category enables
- Option B: Move to Home Manager (user-level apps)
- Option C: Keep in machine files directly

#### 7. Leverage monitoring-inventory.nix more
Use it for auto-configuration, assertions, service discovery tags

#### 8. Audit pkgs-* pins strategy
Why 4 separate nixpkgs pins? Why is one named "broken"? Document rationale.

### Lower Priority

#### 9. Add docs/reference/new-machine-checklist.md
Operator guide for adding new machines

#### 10. Flatten or document pkgs-unstable via specialArgs pattern
Modules depending on specialArgs creates hidden coupling

## Explicitly Rejected Ideas

### Don't build the broad namespace
Original proposal wanted `my.*` everywhere. Current targeted approach is better:
- Only add `my.*` when coordinating multiple modules
- Keep direct upstream config for everything else
- Avoid 1:1 wrapper syndrome

### Don't add broad role modules
"Workstation" and "server" profiles don't fit—machines are too divergent

### Don't extract stateVersion
Must stay machine-specific per NixOS requirements (accepted)

### Don't "fix" mitigations=off
Present for performance reasons, intentional (accepted)

## Architecture Principles Confirmed

1. **Explicit over implicit** - Module import lists show what's enabled
2. **Coordination via my.* options** - Only when cross-module agreement needed
3. **Capability modules over roles** - Compose features, don't hide them
4. **Machine files as integration layer** - Wire capabilities, override defaults
5. **mkNixosSystem as factory** - Consistent machine instantiation pattern

## Open Questions for Future

1. Should `desktopEnvironment` parameter be dropped in favor of explicit module imports?
2. Should flatpaks move entirely to Home Manager (user-level)?
3. Should we create transparent preset bundles (`base-server.nix`, `base-workstation.nix`)?
4. Is the pkgs-unstable via specialArgs pattern the right long-term approach?

## Next Actions

When ready to proceed:
1. Implement firewall pattern extraction (Priority #1)
2. Implement remote access mode option (Priority #2)
3. Write configuration-layers.md documentation (Priority #3)
4. Review and decide on medium-priority items
