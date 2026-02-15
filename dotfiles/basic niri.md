**Short version first:**

* **Niri is a Wayland compositor**, not a full desktop environment. Think *window manager + compositor*, not GNOME/KDE.
* It gives you a **scrollable tiling workflow** (similar mindset to PaperWM / dynamic workspaces).
* Everything beyond window management — dock, top bar, notifications, system tray, settings — comes from **separate components** you assemble yourself.
* On **Nix/NixOS**, you usually configure it declaratively via Nix + config files.
* There is **no official GUI configurator**; configuration is mostly file-based (KDL or Nix abstraction).

I’ll explain how it works conceptually, then show how to build a **“Mac-like” desktop** on top of it.

---

## 1) How niri actually works

### Core idea: scrollable tiling

Instead of traditional workspaces:

* Windows are arranged in **columns** on an infinite horizontal strip.
* New windows do **not resize existing ones** (very different from i3/sway).
* You scroll left/right through windows.
* Workspaces are vertical and dynamic.

Conceptually:

```
Workspace 1:
[Terminal] [Browser] [Editor] [Music]
    <---- scroll ---->

Workspace 2:
[Docs] [Chat]
```

Each monitor has independent workspace stacks. This is one of niri’s defining design decisions. ([GitHub][1])

---

### What niri does *not* include

Out of the box, niri does NOT provide:

* Dock
* Top panel
* Notification center
* Network / battery icons
* Settings app
* App launcher
* Lock screen
* Polkit dialogs

You add those manually (similar to sway / Hyprland philosophy). ([wiki.nixos.org][2])

---

## 2) Architecture: think LEGO pieces

A typical niri setup looks like:

```
┌─────────────────────────────┐
│   Waybar (top bar)          │
│  stats | workspaces | icons │
├─────────────────────────────┤
│                             │
│        NIRI                 │
│   (window management)       │
│                             │
└─────────────────────────────┘
Dock (eww / waybar / nwg-dock)
```

Common components:

| Function           | Typical tool         |
| ------------------ | -------------------- |
| Panel / status bar | Waybar               |
| Notifications      | mako                 |
| App launcher       | fuzzel / rofi / wofi |
| Wallpaper          | swaybg               |
| Lock screen        | swaylock             |
| Idle handling      | swayidle             |
| Auth prompts       | polkit agent         |
| Clipboard manager  | wl-clipboard helpers |

---

## 3) Niri on Nix (recommended setup)

On NixOS, the minimal enablement is simple:

```nix
programs.niri.enable = true;
```

That installs the compositor itself. ([wiki.nixos.org][2])

But you typically also enable:

```nix
programs.waybar.enable = true;
services.mako.enable = true;
```

---

### Configuration location

Native niri config:

```
~/.config/niri/config.kdl
```

It uses **KDL**, not JSON/YAML.

Example structure:

```kdl
input {
  keyboard {
    xkb {
      layout "us"
    }
  }
}

binds {
  Mod+Return { spawn "alacritty"; }
}
```

Config reloads live — no restart needed.

---

### Nix-native config (optional advanced)

Some people use `niri-flake` so config becomes pure Nix:

```nix
programs.niri.settings = { ... };
```

But many users prefer normal KDL because iteration is faster. ([GitHub][3])

---

## 4) Building a macOS-like niri desktop

Let’s translate your request into components.

---

## A) Top-right connectivity & system icons

Use **Waybar**.

Waybar supports:

* WiFi
* Bluetooth
* Battery
* Audio
* VPN
* Clock
* Media controls
* System tray

Config snippet:

```json
{
  "modules-right": [
    "pulseaudio",
    "network",
    "bluetooth",
    "battery",
    "clock",
    "tray"
  ]
}
```

Waybar is basically the standard choice for niri. ([davidyat.es][4])

---

### Visual example (top bar style)

![Image](https://leni.sh/_app/immutable/assets/screenshot.njTkUaS-.jpg)

![Image](https://www.phoronix.net/image.php?id=2024\&image=niri_011)

![Image](https://repository-images.githubusercontent.com/510090159/90c9387d-2688-413b-9134-7ce04a8a31d1)

![Image](https://opengraph.githubassets.com/13597b7286d18a3b46ba16cff22aa0d9fde2acd33c6bfd2bb6cb56b0bca78091/ashish-kus/waybar-minimal)

---

## B) Dock (macOS-like bottom launcher)

niri itself has no dock.

Popular options:

### 1️⃣ Waybar as dock (easiest)

* Set bottom panel
* icon-only taskbar
* always visible

### 2️⃣ nwg-dock

* lightweight dock for wlroots compositors

### 3️⃣ eww (highly customizable)

* lets you build animated docks
* closest to real macOS style

Many people use:

```
niri + waybar + eww
```

---

## C) Usage stats on the left

Again: Waybar modules.

Example modules:

```
cpu
memory
temperature
disk
network throughput
```

You can place them left side:

```json
"modules-left": ["cpu", "memory", "temperature"]
```

---

## D) App launcher (Spotlight replacement)

Best matches:

* **fuzzel** → minimal, fast
* **rofi-wayland** → more customizable

Bind in niri:

```kdl
binds {
  Mod+D { spawn "fuzzel"; }
}
```

---

## E) Notifications & control center

macOS-like notifications:

* `mako` = minimal daemon
* optional: custom widgets via eww

---

## F) Settings UI?

This part surprises many users.

### There is NO central settings app.

You configure:

* niri → config.kdl
* waybar → JSON + CSS
* launcher → its own config
* notifications → mako config
* themes → GTK/Qt settings

This is very UNIX-style composability.

---

## 5) Is there a GUI configurator?

### Official answer: **No**

niri deliberately avoids a GUI settings tool.

Reasons:

* compositors are modular
* configs are text-first
* target audience = power users

Some community shells exist (IgnisShell, etc.) but they’re not mature desktop-like replacements yet. ([GitHub][5])

---

## 6) Mental model vs macOS

| macOS                         | niri ecosystem         |
| ----------------------------- | ---------------------- |
| WindowServer + Dock + MenuBar | niri + waybar + extras |
| System Settings               | many config files      |
| Mission Control               | niri overview          |
| Spaces                        | vertical workspaces    |
| Dock zoom                     | custom dock app        |
| Spotlight                     | fuzzel                 |

---

## 7) Beginner advice (important)

If this is your first tiling compositor on Nix:

Start simple:

1. niri
2. waybar
3. fuzzel
4. mako
5. swaybg

Then add:

* dock
* widgets
* fancy animations

Trying to mimic macOS immediately often leads to config overload.

---

## 8) What people love about niri (quick summary)

* Smooth scroll workflow (very addictive)
* Windows never resize unexpectedly
* Great multi-monitor behavior
* Clean Rust codebase
* Dynamic workspaces without clutter ([GitHub][1])

---

## 9) What I’d recommend for *your* goal specifically

You said:

> Mac OS style: dock + top right icons + usage stats left

So your stack should be:

```
niri
+ waybar (top panel)
+ waybar or eww dock
+ mako notifications
+ fuzzel launcher
+ swaybg wallpaper
```

That gets you ~90% of the macOS feel while keeping niri’s workflow.

---

## 10) If you want, next I can show you…

I can give you one of these (your choice):

1️⃣ **A complete NixOS starter config** for niri + macOS-like layout
2️⃣ A **minimal clean setup** that looks polished in 15 minutes
3️⃣ A **hardcore “Apple-like” rice** (dock animations, blur, widgets, etc.)
4️⃣ A diagram showing how all components talk to each other (helps a LOT)

Just tell me how deep you want to go 👍.

[1]: https://github.com/YaLTeR/niri?utm_source=chatgpt.com "GitHub - YaLTeR/niri: A scrollable-tiling Wayland compositor."
[2]: https://wiki.nixos.org/wiki/Niri?utm_source=chatgpt.com "Niri - Official NixOS Wiki"
[3]: https://github.com/sodiboo/niri-flake?utm_source=chatgpt.com "GitHub - sodiboo/niri-flake: Nix-native configuration for niri"
[4]: https://davidyat.es/2026/01/28/niri/?utm_source=chatgpt.com "Niri's infinite canvas"
[5]: https://github.com/lost-melody/IgnisNiriShell?utm_source=chatgpt.com "GitHub - lost-melody/IgnisNiriShell: An ignis config for niri compositor"

Below is a **practical starter setup** for NixOS + niri that gives you a clean “macOS-ish” workflow, followed by a **clear architecture diagram** so the whole system makes sense mentally.

---

# 1️⃣ NixOS starter config (macOS-style layout)

Goal:

* Top bar (right = system icons, left = stats)
* Dock-like app launcher
* Scrollable tiling from niri
* Notifications + launcher
* Clean defaults that you can evolve later

This assumes:

* NixOS (not just Home-Manager)
* Wayland session
* You log in via a display manager (GDM, SDDM, etc.)

---

## A) Enable niri + core components

Add to `configuration.nix`:

```nix
{
  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    waybar
    fuzzel
    mako
    swaybg
    wl-clipboard
    pavucontrol
    networkmanagerapplet
  ];

  services.dbus.enable = true;
  security.polkit.enable = true;

  # Optional but recommended
  programs.dconf.enable = true;
}
```

---

## B) Minimal niri config

Create:

```
~/.config/niri/config.kdl
```

Example starter:

```kdl
input {
  keyboard {
    xkb {
      layout "us"
    }
  }
}

layout {
  gaps 10
  border {
    width 2
  }
}

binds {
  Mod+Return { spawn "alacritty"; }
  Mod+D { spawn "fuzzel"; }

  Mod+Q { close-window; }

  Mod+H { focus-column-left; }
  Mod+L { focus-column-right; }

  Mod+Shift+H { move-column-left; }
  Mod+Shift+L { move-column-right; }

  Mod+Space { toggle-column-maximized; }
}

spawn-at-startup "waybar"
spawn-at-startup "mako"
spawn-at-startup "swaybg -i ~/Pictures/wallpaper.jpg -m fill"
```

What this gives you:

* macOS-style “single large app” focus via maximize
* horizontal navigation similar to desktops/spaces
* clean padding

---

## C) Waybar (your top panel)

Create:

```
~/.config/waybar/config.jsonc
```

```json
{
  "layer": "top",
  "position": "top",

  "modules-left": [
    "cpu",
    "memory",
    "temperature"
  ],

  "modules-center": [
    "niri/workspaces"
  ],

  "modules-right": [
    "pulseaudio",
    "network",
    "bluetooth",
    "battery",
    "clock",
    "tray"
  ]
}
```

This maps almost directly to what you asked:

* **Left → usage stats**
* **Right → connectivity + system icons**
* **Center → workspace indicator**

---

## D) Waybar styling (clean macOS vibe)

Create:

```
~/.config/waybar/style.css
```

```css
* {
  font-family: Inter, sans-serif;
  font-size: 13px;
}

window#waybar {
  background: rgba(20,20,20,0.75);
  backdrop-filter: blur(8px);
  border-radius: 10px;
}

#workspaces button {
  padding: 0 8px;
  border-radius: 8px;
}

#clock, #battery, #network, #cpu, #memory {
  padding: 0 8px;
}
```

This already feels surprisingly “Apple-like”.

---

## E) Dock options (important choice)

### EASY PATH (recommended first)

Use a **second Waybar** at the bottom:

Create another config:

```
~/.config/waybar/dock.jsonc
```

```json
{
  "layer": "top",
  "position": "bottom",
  "modules-center": ["wlr/taskbar"]
}
```

Launch it:

```kdl
spawn-at-startup "waybar -c ~/.config/waybar/dock.jsonc"
```

Result:

* app icons
* click to focus
* simple dock feel

---

### ADVANCED PATH (later)

Switch to:

* `eww` → animated Mac-like dock
* blur / magnification effects

But don’t start here — complexity spikes fast.

---

## F) Notifications (mako)

Create:

```
~/.config/mako/config
```

```ini
anchor=top-right
default-timeout=5000
border-radius=10
background-color=#1e1e2ecc
text-color=#ffffff
```

---

## G) Launcher (Spotlight vibe)

Default:

```bash
fuzzel
```

Bind already:

```
Mod + D
```

You can later style it like Spotlight.

---

## H) What this setup feels like

You’ll get:

* Smooth horizontal app flow
* Top menu/status area
* Dock-like app switching
* Clean minimal visuals
* No heavyweight desktop environment

---

# 4️⃣ How all pieces fit together (architecture diagram)

This is the most important part for understanding niri.

---

## Core architecture

```
┌───────────────────────────────────────┐
│                Linux                  │
│      (kernel + graphics drivers)      │
└───────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│                Wayland                │
│        protocol (communication)       │
└───────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────┐
│                NIRI                   │
│  - window placement                   │
│  - input handling                     │
│  - rendering                          │
│  - workspace logic                    │
└───────────────────────────────────────┘
       │          │            │
       │          │            │
       ▼          ▼            ▼
   Waybar       Mako         Fuzzel
  (panel)   (notifications) (launcher)

       │
       ▼
   Dock / widgets (Waybar or Eww)
```

---

## Important mental model

Niri is NOT:

```
macOS = one giant system
```

Niri IS:

```
small composable tools cooperating via Wayland
```

---

## Data flow example (click WiFi icon)

```
User click → Waybar module
          → NetworkManager (DBus)
          → system changes
          → Waybar refreshes
```

Niri doesn’t care — it only manages windows.

---

## Why power users like this

You can replace **any piece**:

| Want different panel? | swap Waybar |
| Want iOS-like widgets? | add eww |
| Want GNOME-style shell? | use ags/ignis |
| Want minimal? | remove everything |

---

## Reality check (important)

If you want:

* macOS polish
* animations
* integrated settings GUI

→ GNOME or KDE is easier.

If you want:

* control
* speed
* predictable windows
* zero DE bloat

→ niri is excellent.

---

# ⭐ If you want the *real* next-level upgrade

I can show you next:

🔥 **The “pro” niri layout** most users eventually evolve into:

* hidden auto-dock
* overview mode
* workspace previews
* macOS-like app switching
* blur + rounded corners
* trackpad gesture setup

That’s where niri starts feeling seriously premium.
Alright — this is the **expert-level niri workflow**.
This is not about cosmetics anymore. It’s about **cognitive load reduction** and turning the compositor into an extension of your thinking.

Most people never reach this stage because they keep treating niri like a desktop instead of a **workflow engine**.

---

# 🧠 1) Core mindset shift (the real upgrade)

Beginners think:

> “How do I arrange windows?”

Experts think:

> “Where does this *activity* live?”

You stop managing windows and start managing **flows**.

---

## Spatial workflow model

Instead of random workspaces:

```
WS1  Coding
WS2  Research / Browser
WS3  Communication
WS4  Monitoring / Music
WS5  Scratch / temp
```

Inside each workspace:

```
left  = reference
center = focus task
right = supporting tool
```

Because niri keeps window sizes stable, this becomes muscle memory.

---

# 🧭 2) Column semantics (THIS is the big unlock)

Assign meaning to positions:

| Position | Meaning               |
| -------- | --------------------- |
| Far left | long-term references  |
| Center   | current work          |
| Right    | temporary/helper apps |

Example:

```
[Docs] [Editor] [Terminal] [Logs]
```

You scroll, not rearrange.

After a week your brain maps tasks spatially.

---

# ⚡ 3) Instant workspace spawning (expert trick)

You almost never pre-create workspaces.

Instead:

```
new app → new workspace if context changes
```

Bind:

```kdl
Mod+Shift+Return { move-window-to-workspace "new"; }
```

Workflow:

* deep focus → spawn clean workspace
* done → close and it disappears

No clutter.

---

# ⌨️ 4) Replace alt-tab completely

Alt-tab is linear and slow.

Expert niri flow:

```
Mod+H / Mod+L  -> move horizontally
Mod+Tab        -> overview jump
```

You think spatially:

> “Browser is two steps left.”

This is faster than visual scanning.

---

# 🚀 5) Smart app rules (huge productivity boost)

You stop manually placing apps.

Example concept:

```
Browser always → WS2
Slack always → WS3
Music → WS4
```

Pseudo rule style:

```kdl
window-rule {
  match app-id="firefox"
  open-on-workspace "2"
}
```

Result:

* apps open where your brain expects them
* zero repositioning

This feels *very* macOS-like (Spaces behavior).

---

# 🧩 6) Multi-monitor expert setup

Beginners mirror workflows across monitors.

Experts assign roles:

```
Monitor 1 → focus work
Monitor 2 → persistent context
```

Example:

Main monitor:

* coding / creation

Side monitor:

* chat
* logs
* dashboards

niri’s independent workspaces per monitor make this insanely clean.

---

# 🎯 7) The “Focus Funnel” technique (advanced)

Goal: reduce visual noise.

Rule:

Only ONE maximized column at a time.

Bind:

```kdl
Mod+F { maximize-column; }
```

Flow:

* enter deep focus → maximize
* quick reference → scroll slightly
* back → maximize again

This mimics macOS fullscreen without the drawbacks.

---

# 🧠 8) Scratchpads (expert-only power move)

You need transient tools:

* calculator
* quick terminal
* AI chat
* notes

Use floating scratchpads.

Example concept:

```
Mod+`
```

toggles dropdown terminal.

Why this matters:

* no workspace pollution
* instant access
* no context switch

---

# 🧭 9) Expert launcher workflow (Spotlight killer)

Use fuzzel as:

* app launcher
* calculator
* emoji picker
* clipboard history
* file opener

Common stack:

```
fuzzel + cliphist + fd + zoxide
```

One launcher for everything.

---

# 🖱️ 10) Minimal mouse philosophy

Experts reduce mouse movement drastically.

Typical usage:

* trackpad only for scrolling columns
* clicking mainly for external apps
* everything else keyboard-driven

---

# 🧱 11) The hidden killer feature: predictability

Most WMs resize windows constantly.

niri does NOT.

This creates:

* long-term spatial memory
* lower mental fatigue
* faster context recall

This is the *real* reason people become obsessed with niri.

---

# 🧠 12) Workflow example (real expert flow)

Morning:

```
WS1 → code
WS2 → docs
WS3 → chat
WS4 → monitoring
```

Working:

1. Focus editor (center column)
2. Scroll left for docs
3. Scroll right for logs
4. Mod+Tab overview jump if needed

No dragging. No arranging. No thinking about layout.

---

# 🔥 13) Pro visual polish (high signal only)

Experts usually end up with:

* almost invisible top bar
* auto-hide dock
* dark translucent surfaces
* no desktop icons
* minimal notifications

Goal: UI disappears.

---

# 🧨 14) The three stages of niri mastery

### Stage 1 — Tiling user

* managing windows manually

### Stage 2 — Workflow user

* assigning workspaces

### Stage 3 — Expert (you’re aiming here)

* spatial memory replaces window management

---

# 🧬 15) The secret most guides don’t tell you

niri isn’t competing with:

* GNOME
* KDE
* Hyprland

It’s closer to:

> **A spatial IDE for your entire computer**

Once your brain maps columns, switching back feels chaotic.

---

# ⭐ If you want the *real final upgrade*…

There’s one final level most users never reach:

## 🧠 “Zero-friction niri”

* apps restore exact positions after reboot
* workspace state persistence
* instant project layouts (one hotkey)
* automatic monitor layout switching
* session templates

This turns niri into something macOS and even i3 can’t replicate.

If you want that, say:

> **“Show me the zero-friction niri setup.”**

That’s the “I can never go back” stage.

The things I've tried setting up my workspace just like that using gnome and paperwm. Most of it is exactly what you describe in expert level, except that I could not make it predictable. 

Add the first 2 zero friction niri points: exact restore position and workspace state persistence. Comment out all the options by tear so I can gradually start using them myself. 

You ran into the exact failure mode of PaperWM-on-GNOME: **the layout concept is right, but the system can’t reliably restore state**, so “predictable” never becomes muscle memory.

For niri, the **two “zero-friction” points** you asked for are typically achieved like this:

1. **Workspace state persistence** (workspace names/indices/outputs + what apps were where)
2. **Exact restore position** (practically: restoring each app back to the same *workspace* and same *relative order/geometry* so the view feels identical)

niri itself is intentionally lean; session persistence is typically done via a **session manager using niri’s IPC**, e.g. **`nirinit`**, which explicitly advertises saving/restoring window layout and workspace metadata. ([GitHub][1])

Below is a setup where **everything is staged in tiers and commented out**, so you can enable it gradually.

---

## Tier 0 — Make workspaces deterministic (foundation)

This alone already beats a lot of “GNOME unpredictability”.

### `~/.config/niri/config.kdl` (Tier 0)

```kdl
// Niri config is KDL. In niri configs, you can comment with `//`
// and you can disable a node with `/-` (comments out the following node). :contentReference[oaicite:1]{index=1}

binds {
  Mod+Return { spawn "alacritty"; }
  Mod+D { spawn "fuzzel"; }

  // Overview = your “Mission Control” muscle-memory key.
  Mod+Tab { toggle-overview; }
}

// --- Tier 0: “Predictable places” via named workspaces + window rules ---
// Named workspaces make numbers stable (important for predictability).
// (Niri supports named workspaces; window rules are the mechanism.) :contentReference[oaicite:2]{index=2}

// Example: route apps into stable workspaces.
// IMPORTANT: match keys depend on app_id/title; check `app_id` with `niri msg` tooling or docs.
// Keep these commented until you’re ready to commit to a map.

/-
window-rule {
  match app-id="firefox"
  open-on-workspace "2:research"
}

/-
window-rule {
  match app-id="Slack"
  open-on-workspace "3:comms"
}

/-
window-rule {
  match app-id="spotify"
  open-on-workspace "4:media"
}
```

**What you enable first:** uncomment one rule at a time (remove the leading `/-`).
This gets you the “apps always land where I expect” effect—without any persistence yet.

---

## Tier 1 — Workspace state persistence (session save/restore)

For this, use **`nirinit`**. It’s a session manager for niri that auto-saves and restores windows/workspaces, including workspace names/indices/outputs and window sizes. ([GitHub][1])

### NixOS: install + user service (Tier 1)

Add to `configuration.nix` (or Home Manager equivalents):

```nix
{
  environment.systemPackages = with pkgs; [
    nirinit
  ];

  # Tier 1: start the session manager in your user session
  systemd.user.services.nirinit = {
    description = "nirinit (niri session manager)";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.nirinit}/bin/nirinit";
      Restart = "on-failure";
    };
  };
}
```

**Enable step-by-step:**

* First just install `nirinit` (leave the service commented in your Nix if you want).
* Then enable the systemd user service.

This gives you **“workspace state persistence”** (apps come back to their workspaces and the workspace metadata is preserved) with minimal fuss. ([GitHub][1])

---

## Tier 2 — “Exact restore position” (as close as reality allows)

Important nuance: on Wayland, “exact position” is partly defined by compositor state and partly by **app behavior** (some apps restore their own window sizes/state; some don’t). What you *can* make very consistent is:

* workspace target (exact)
* column ordering (usually exact if restore is deterministic)
* window sizes (often exact; `nirinit` explicitly claims size preservation) ([GitHub][1])
* view position stability during transient changes is already a niri design goal ([GitHub][2])

### Add a dedicated `nirinit` config (Tier 2)

Create: `~/.config/nirinit/config.toml` (example pattern; adjust to actual nirinit docs if needed)

```toml
# --- Tier 1 defaults (safe) ---
autosave = true
autosave_interval_seconds = 300

# --- Tier 2: improve “exact restore” determinism ---
# Map app_id to exact launch commands so restore spawns the right thing.
# Start with ONE app, then expand gradually.

# [launch]
# "firefox" = ["firefox"]
# "Slack"   = ["slack"]
# "spotify" = ["spotify"]

# Skip things that should NOT be restored (transient dialogs, etc.)
# [ignore]
# app_ids = ["pavucontrol", "org.gnome.Calculator"]
```

Then change the systemd ExecStart to point at the config (commented, so you can tier it):

```nix
# Tier 2 (commented): use an explicit nirinit config
# serviceConfig.ExecStart = "${pkgs.nirinit}/bin/nirinit --config %h/.config/nirinit/config.toml";
```

**Enable step-by-step:**

1. Turn on autosave + restore only
2. Add **one** launch mapping (browser)
3. Add comms apps
4. Add ignore list

This is the phase where it stops feeling “random” after reboot/login.

---

## Practical “gradual enable” checklist

**Week 1**

* Tier 0: only one window-rule (browser → research workspace)

**Week 2**

* Tier 1: enable `nirinit` service (no launch mappings)

**Week 3**

* Tier 2: add launch mappings for 2–3 core apps + ignore list for junk windows

---

## One thing that’s worth doing immediately

Even before persistence: **name your workspaces** and stick to a fixed semantic map. That’s the missing piece in GNOME setups where workspace identity drifts.

---

If you tell me which apps you want pinned to which “semantic workspaces” (e.g., Firefox=Research, Slack=Comms, Terminal=Dev), I’ll write you a clean set of **Tier-0 window rules** that are *likely to match correctly* (app_id/title matching is the only fiddly part).

[1]: https://github.com/amaanq/nirinit?utm_source=chatgpt.com "amaanq/nirinit: A session manager for Niri, a scrollable- ..."
[2]: https://github.com/YaLTeR/niri/wiki/Development%3A-Design-Principles?utm_source=chatgpt.com "Development: Design Principles · niri-wm/niri Wiki"

Here’s a **clean, Codex-friendly `workflow.md`** you can drop into your repo (for example: `docs/setup/niri-workflow.md`).

This is written specifically to:

* preserve the design decisions you made here
* give Codex persistent context
* prevent config drift
* keep your tier system intact as you evolve it

---

```md
# Niri Workflow — Predictable Spatial Desktop

## Purpose

This setup aims to create a **predictable, low-friction spatial workflow** similar in feel to macOS + PaperWM, but with stronger determinism.

Primary goals:

- Stable spatial memory
- Deterministic workspace behavior
- Minimal window management overhead
- Recoverable session state after reboot
- Gradual complexity via tiers

---

## Core Philosophy

### 1. Activity-based Workspaces (NOT app-based chaos)

Workspaces represent **activities**, not temporary window collections.

Recommended semantic layout:

| Workspace | Purpose |
|---|---|
| 1:dev | coding, terminal, IDE |
| 2:research | browser, docs |
| 3:comms | chat, mail |
| 4:media | music, monitoring |
| 5:scratch | temporary tasks |

Workspaces should remain stable long-term.

---

### 2. Column Semantics

Inside each workspace:

| Position | Meaning |
|---|---|
| Left | reference / long-lived context |
| Center | current focus |
| Right | temporary helper tools |

Avoid manual rearranging.

Scroll horizontally instead.

---

### 3. Predictability > Flexibility

Rules:

- Apps should always open in expected workspaces.
- Window sizes should remain stable.
- Avoid layouts that reflow unexpectedly.
- Prefer consistency over dynamic behavior.

---

## Tier System

All configuration evolves gradually.

### Tier 0 — Foundation

- Basic keybindings
- Scrollable tiling
- Stable gaps/presets
- No automation

Goal:
Learn native niri navigation first.

---

### Tier 0.5 — Semantic Workspace Routing

Window rules enforce predictable placement.

Examples:

- Firefox → `2:research`
- VSCode → `1:dev`
- Slack → `3:comms`
- Spotify → `4:media`

Only enable one rule at a time.

---

### Tier 1 — Desktop Shell

Adds UX components:

- Waybar top panel
- Dock (Waybar initially)
- Mako notifications
- Wallpaper

Rule:
UI must remain visually quiet.

---

### Tier 2 — Zero-Friction Session

Session persistence via `nirinit`.

Goals:

- Workspace state restoration
- Deterministic restore order
- Minimal manual reopening

Important:
Persistence should reinforce spatial memory, not fight it.

---

### Tier 2.5 — Deterministic Restore

Add explicit launch mappings:

- app_id → launch command

Exclude transient windows from restore.

---

### Tier 3 — Quality of Life

Optional:

- Clipboard history
- Lock screen
- Idle handling
- Auto-hide dock (eww)
- Animated wallpaper

Only enable after tiers 0–2 feel stable.

---

## Navigation Model

### Replace Alt-Tab

Primary navigation:

- `Mod + H/L` → horizontal movement
- `Mod + Tab` → overview jump
- `Mod + F` → focused maximize

Goal:
Think spatially, not linearly.

---

## Focus Strategy

Use a “focus funnel”:

1. Work in centered column
2. Maximize when deeply focused
3. Scroll briefly to references
4. Return to focus

Avoid juggling many visible windows.

---

## Multi-Monitor Principle

Roles should differ per monitor:

- Main monitor → active work
- Secondary monitor → persistent context (chat/logs/music)

Never mirror workflows across monitors.

---

## Persistence Strategy

Predictability comes from layering:

1. Workspace rules (Tier 0.5)
2. Consistent app IDs
3. Session persistence (Tier 2)

If restore feels random:

- verify app_id matching
- simplify rules
- reduce auto-launch noise

---

## What NOT To Do

- Do not dynamically rename workspaces often.
- Do not rely on manual window placement.
- Do not introduce heavy widget systems early.
- Do not optimize visuals before workflow stabilizes.

---

## Troubleshooting Principles

If predictability degrades:

1. Disable newest tier first.
2. Verify workspace rules.
3. Check app_id changes.
4. Restore minimal Tier 0 baseline.

---

## Future Enhancements (Expert)

Potential upgrades:

- Auto-hide animated dock (eww)
- Gesture integration
- Project-specific workspace templates
- Session-aware launch scripts
- Monitor-profile layouts

---

## Notes for Codex / AI Assistants

When editing configs:

- Preserve the tier structure.
- Prefer commenting features instead of deleting them.
- Maintain workspace semantics.
- Avoid introducing unpredictable auto-layout behavior.
- Prioritize deterministic startup and restore.

```

---

## 🔥 Why this matters (important)

This file becomes:

* your **single source of truth**
* Codex’s persistent memory
* protection against “configuration entropy”

Whenever Codex changes your config, it now has a philosophy to follow.

---

If you want, I can also give you the **“Codex-native next step”** that almost nobody uses — and it’s insanely powerful:

🧠 a tiny `README_FOR_AI.md` that makes Codex automatically maintain your niri setup like a system architect instead of a code assistant.

This is the thing that turns your config into a *self-improving environment*.

Below is a **generic, reusable `README_FOR_AI.md`** designed for an entire dotfiles repo — not just niri.

It teaches Codex (or any AI agent in your IDE) how to behave as a **configuration maintainer** across your whole system while still supporting tiered, predictable workflows.

You can drop this at:

```
~/dotfiles/README_FOR_AI.md
```

It is intentionally:

* distro-agnostic (works for NixOS, Arch, Fedora, etc.)
* compositor-agnostic (niri, sway, Hyprland, GNOME tweaks, etc.)
* shell/editor neutral
* focused on **stability + incremental change**

---

# `README_FOR_AI.md`

```md
# README_FOR_AI — Dotfiles Maintenance Guide

## Purpose

This repository contains personal dotfiles and system configuration.

Your role is:

**Configuration maintainer and workflow engineer**, not a feature explorer.

Primary goals:

1. Predictability
2. Stability
3. Incremental improvements
4. Low cognitive load

Changes must preserve workflow continuity.

---

## Core Philosophy

### 1. Predictability > Novelty

Prefer:

- stable defaults
- explicit behavior
- deterministic startup
- clear structure

Avoid:

- clever but opaque automation
- auto-generated configs
- breaking workflow assumptions

---

### 2. Incremental Complexity (Tier Model)

Features should be layered in tiers.

General structure:

- Tier 0 — minimal working baseline
- Tier 1 — usability enhancements
- Tier 2 — automation / persistence
- Tier 3 — advanced QoL or experimentation

Rules:

- New features must be added COMMENTED OUT by default.
- Do not enable advanced tiers automatically.
- Preserve existing tier comments and structure.

---

### 3. Preserve Spatial & Muscle-Memory Workflows

If window managers/compositors are involved:

- avoid changes that alter navigation patterns
- keep workspace semantics stable
- favor deterministic placement rules

---

## Repository Structure (Expected)

Typical layout:

```

dotfiles/
README_FOR_AI.md
docs/
configs/
niri/
waybar/
shell/
git/
editor/
scripts/

```

If structure differs, adapt but DO NOT aggressively reorganize.

---

## Source of Truth

Before editing anything, read:

1. `docs/` (workflow philosophy and design decisions)
2. Existing config comments
3. Startup scripts/services

If intent is unclear:

- preserve behavior
- add comments instead of rewriting

---

## Editing Rules (STRICT)

When modifying configs:

- Preserve comments.
- Prefer additive edits.
- Never delete working configurations unless explicitly asked.
- Keep formatting style consistent.

When introducing new functionality:

- Add as a clearly labeled block.
- Include enable/disable instructions.
- Use comments rather than removal.

---

## Startup & Services

Avoid startup conflicts.

Checklist:

- Do not launch the same service from multiple places.
- Prefer one startup system:
  - systemd user services
  - OR compositor/session autostart
  - OR shell startup
- If unsure, document instead of changing.

---

## Dotfile Categories

### Shell (bash/zsh/fish)

Goals:

- fast startup
- predictable aliases
- readable prompt

Avoid:

- heavy frameworks unless already present
- hidden side effects in shell init

---

### Editor (Neovim, VSCode, etc.)

Goals:

- stable keybindings
- reproducible plugins
- clear separation between UI and behavior

Avoid:

- changing core keymaps without explicit request.

---

### Window Manager / Compositor

Goals:

- deterministic layouts
- stable keybinds
- minimal visual noise

Rules:

- workspace semantics must remain stable
- avoid auto-layout tricks that reduce predictability
- prefer explicit rules over implicit behavior

---

### Bars / Widgets / UI

Goals:

- informational, not distracting
- consistent visual language

When editing:

- avoid large visual redesigns
- keep module order stable unless requested

---

### Notifications / System UX

Prefer:

- quiet defaults
- reduced notification noise
- explicit modes for focus (DND)

---

## Automation & Persistence

When adding automation:

1. Ensure it reinforces predictability.
2. Avoid hidden background behavior.
3. Document restore/launch order clearly.

---

## Safety Rules

Do NOT:

- replace entire toolchains without request
- migrate to new frameworks automatically
- remove compatibility for existing workflows
- introduce random experimental tools

---

## AI-Specific Instructions

When making suggestions:

- Prefer minimal diffs.
- Explain tradeoffs briefly.
- Keep user control high.
- Default to conservative changes.

If uncertain:

- add TODO comments instead of guessing.

---

## Workflow Preservation

Assume user values:

- muscle memory
- stable keybindings
- spatial consistency
- minimal surprises after reboot

Any change threatening these must be optional.

---

## Repository Health

When improving structure:

- Add docs rather than restructure aggressively.
- Group related configs but preserve history.
- Avoid unnecessary file moves.

---

## Change Checklist (Before Finalizing)

- [ ] Existing behavior preserved
- [ ] Tier structure maintained
- [ ] New features commented out
- [ ] Startup conflicts avoided
- [ ] Comments added for non-obvious behavior
- [ ] No silent workflow changes

---

## Preferred Output Style

When proposing changes:

1. Show affected files.
2. Provide concise explanation.
3. Include enable steps if relevant.
4. Avoid large rewrites unless requested.

```

---

## 🧠 Why this works (important)

This file turns Codex from:

> “assistant that edits files”

into:

> **system steward that protects your workflow**

Especially important for dotfiles, where entropy usually kills setups over time.

---

## 🔥 Highly recommended next step (seriously)

Add this tiny file too:

```
docs/workflow-principles.md
```

with **5–10 lines about how you personally work** (keyboard-first, minimal UI, etc.).

Codex uses that as behavioral context and becomes dramatically better.

---

If you want, I can give you the **dotfiles repo structure used by long-term Linux power users** — the one that survives distro hops and compositor changes without rewrites.

Here’s the **dotfiles repo structure** many long-time Linux power users eventually converge to — because it survives:

* distro changes (NixOS ↔ Arch ↔ Fedora)
* compositor swaps (niri ↔ sway ↔ Hyprland ↔ GNOME)
* shell/editor migrations
* and years of incremental evolution

The core idea:

> **Separate “intent” from “implementation”.**

---

# 🧱 1️⃣ High-level structure (battle-tested)

```
dotfiles/
│
├── README.md
├── README_FOR_AI.md
│
├── docs/
│   ├── workflow-principles.md
│   ├── system-philosophy.md
│   └── decisions/
│       ├── 0001-workspace-model.md
│       └── 0002-shell-choice.md
│
├── hosts/
│   ├── laptop/
│   ├── desktop/
│   └── vm/
│
├── modules/
│   ├── compositor/
│   │   ├── niri/
│   │   ├── sway/
│   │   └── hyprland/
│   │
│   ├── ui/
│   │   ├── waybar/
│   │   ├── notifications/
│   │   └── launcher/
│   │
│   ├── shell/
│   │   ├── bash/
│   │   ├── zsh/
│   │   └── fish/
│   │
│   ├── editor/
│   │   ├── nvim/
│   │   └── vscode/
│   │
│   ├── terminal/
│   │   ├── alacritty/
│   │   └── kitty/
│   │
│   └── system/
│       ├── services/
│       ├── fonts/
│       └── themes/
│
├── scripts/
│   ├── install.sh
│   ├── link.sh
│   ├── doctor.sh
│   └── capture-state.sh
│
├── state/
│   ├── workspace-map.md
│   └── app-rules.md
│
└── overlays/   (optional, Nix-specific)
```

---

# 🧠 2️⃣ Why this layout works

Most dotfiles fail because they mix:

* machine-specific things
* workflow philosophy
* config implementation

This layout separates them:

| Folder     | Purpose                    |
| ---------- | -------------------------- |
| `docs/`    | WHY decisions exist        |
| `modules/` | reusable configs           |
| `hosts/`   | machine-specific overrides |
| `state/`   | workflow semantics         |
| `scripts/` | automation                 |

---

# 🔥 3️⃣ The hidden killer idea: `state/`

Almost nobody does this — but experts do.

Example:

```
state/workspace-map.md
```

```md
WS1 = dev
WS2 = research
WS3 = comms
WS4 = media
```

Why it matters:

* Codex reads this
* niri rules stay consistent
* migrations become trivial

Your workflow lives outside configs.

---

# 🧩 4️⃣ Module-first design (super important)

Instead of:

```
~/.config/niri/
~/.config/waybar/
~/.config/mako/
```

You store:

```
modules/compositor/niri/
modules/ui/waybar/
modules/ui/notifications/
```

Then symlink into `~/.config`.

Benefits:

* swap compositor without losing UI configs
* reuse modules across machines
* easier AI editing

---

# ⚙️ 5️⃣ Host-specific configs

This solves laptop vs desktop pain.

Example:

```
hosts/laptop/
```

Contains:

```bash
# monitor layout
# battery settings
# touchpad config
```

Desktop host:

```bash
# multi-monitor layouts
# performance tweaks
```

Your workflow stays identical; only hardware changes.

---

# 🧬 6️⃣ Decision logs (massively underrated)

Folder:

```
docs/decisions/
```

Each file answers:

> WHY did I do this?

Example:

```
0001-workspace-model.md
```

```md
Decision:
Use semantic workspaces instead of dynamic ones.

Reason:
Supports spatial memory and predictable restore.
```

Future-you (and Codex) won’t destroy your system accidentally.

---

# 🤖 7️⃣ AI-optimized structure (this is new-school)

AI tools work best when:

```
docs/ = intent
modules/ = implementation
state/ = workflow rules
```

Codex can infer:

* what must stay stable
* what can be modified

---

# 🧭 8️⃣ Recommended niri-specific placement

```
modules/compositor/niri/config.kdl
modules/ui/waybar/top.jsonc
modules/ui/waybar/dock.jsonc
modules/ui/notifications/mako.conf
```

Then:

```
scripts/link.sh
```

creates symlinks into `~/.config`.

---

# 🧱 9️⃣ The “link.sh” pattern (power user standard)

Example:

```bash
#!/usr/bin/env bash

ln -sf ~/dotfiles/modules/compositor/niri ~/.config/niri
ln -sf ~/dotfiles/modules/ui/waybar ~/.config/waybar
ln -sf ~/dotfiles/modules/ui/notifications ~/.config/mako
```

Advantages:

* instant rollback
* version-controlled configs
* reproducible machines

---

# 🚀 10️⃣ The level most people never reach

Add:

```
scripts/capture-state.sh
```

This snapshots:

* current windows
* workspaces
* monitors
* running apps

You can diff workflow changes over time.

---

# ⭐ 11️⃣ Why this setup survives for years

Because:

* switching from niri → something else only touches one module
* workflow docs stay unchanged
* hosts isolate hardware quirks
* AI tools understand your intent

---

# 🧠 If you want the REAL next step (seriously)

There’s one more evolution that very few people discover:

## 🔥 The “Self-Healing Dotfiles” pattern

Where:

* Codex automatically detects drift
* broken app_ids get repaired
* deprecated options get migrated safely
* configs adapt when tools update

This is where Linux stops feeling fragile.

If you want that, say:

> **Show me self-healing dotfiles.**

And I’ll show you the setup used by people who practically never manually fix configs anymore.

Perfect — this is the **self-healing dotfiles** pattern.

The goal is not automation for its own sake. The goal is:

> Your system quietly repairs drift before it becomes breakage.

This pattern is especially good for:

* Nix + rolling tools
* Wayland compositors (niri / sway / hyprland)
* configs that slowly rot due to renamed options, app IDs, or module changes.

---

# 🧠 1️⃣ What “self-healing” actually means

Not magic. Just three layers:

```
1. Detect drift
2. Diagnose automatically
3. Suggest or apply safe fixes
```

Examples:

* Waybar module renamed → detected during check
* app_id changed → rule mismatch warning
* duplicate autostarts → flagged
* broken symlink → auto-fixed

---

# 🧱 2️⃣ Add a health system to your dotfiles

New structure:

```
dotfiles/
├── health/
│   ├── checks/
│   │   ├── check-symlinks.sh
│   │   ├── check-appids.sh
│   │   ├── check-duplicate-startup.sh
│   │   └── check-deprecated-options.sh
│   │
│   ├── rules/
│   │   └── expected-app-ids.txt
│   │
│   └── doctor.sh
```

Think of this like `cargo check` for your desktop.

---

# 🔎 3️⃣ Core idea: “doctor” command

You run:

```bash
~/dotfiles/health/doctor.sh
```

or let Codex run it automatically.

This script:

* scans configs
* validates assumptions
* shows warnings before things break

---

## Example `doctor.sh`

```bash
#!/usr/bin/env bash
set -e

echo "== Dotfiles Health Check =="

for script in "$(dirname "$0")"/checks/*.sh; do
    echo ""
    echo "-- $(basename "$script") --"
    bash "$script"
done

echo ""
echo "Health check complete."
```

---

# 🧩 4️⃣ Self-healing Check #1 — Broken symlinks

Most dotfile failures = bad links.

### `health/checks/check-symlinks.sh`

```bash
#!/usr/bin/env bash

find ~/.config -xtype l 2>/dev/null | while read -r link; do
    echo "BROKEN LINK: $link"
done
```

You can upgrade later to auto-fix.

---

# 🧠 5️⃣ Self-healing Check #2 — App ID drift (BIG ONE)

This is what broke your PaperWM predictability.

Problem:

Apps change IDs:

```
firefox -> org.mozilla.firefox (flatpak)
```

### `health/rules/expected-app-ids.txt`

```
firefox
code
Slack
spotify
```

### `health/checks/check-appids.sh`

```bash
#!/usr/bin/env bash

echo "Checking known app_ids..."

# get running app IDs from niri IPC (example)
current=$(niri msg windows 2>/dev/null | grep app-id | awk '{print $2}')

while read -r expected; do
    if ! echo "$current" | grep -q "$expected"; then
        echo "WARNING: app_id not found -> $expected"
    fi
done < "$(dirname "$0")/../rules/expected-app-ids.txt"
```

Now you know immediately when rules stop matching.

---

# ⚠️ 6️⃣ Self-healing Check #3 — Duplicate autostarts

This kills Wayland setups silently.

### `check-duplicate-startup.sh`

```bash
#!/usr/bin/env bash

echo "Checking duplicate startup entries..."

grep -R "waybar" ~/.config/niri 2>/dev/null || true
grep -R "waybar" ~/.config/systemd/user 2>/dev/null || true
```

Codex can later improve this into a strict detector.

---

# 🧬 7️⃣ Self-healing Check #4 — Deprecated options

Tool updates break configs.

Basic starter:

```bash
#!/usr/bin/env bash

grep -R "old_option_name" ~/.config/niri \
  && echo "Deprecated niri option detected!"
```

Later you can make this version-aware.

---

# 🤖 8️⃣ How Codex becomes self-healing

Add this to `README_FOR_AI.md`:

```md
Before changing configs:

1. Run health/doctor.sh
2. Fix warnings with minimal changes
3. Preserve tier structure
```

Now Codex will:

* run checks
* detect drift
* patch configs safely

---

# 🔥 9️⃣ The REAL power move (few users know)

Add:

```
scripts/capture-state.sh
```

```bash
niri msg workspaces > state/workspaces.json
niri msg windows > state/windows.json
```

Now you can diff:

```
git diff state/
```

and see workflow drift.

---

# 🧠 10️⃣ Why this changes everything

Without self-healing:

```
Config entropy → small break → rebuild weekend
```

With self-healing:

```
Tiny warnings → tiny fixes → system stays stable
```

---

# ⭐ 11️⃣ The final evolution (seriously next-level)

Once this works, you can add:

## “Adaptive rules”

Where Codex notices:

> You always move app X to workspace 2

and suggests a new window rule automatically.

This is where your desktop starts learning your workflow.

---

If you want, next I can show you something VERY few people understand:

## 🧨 The “anti-fragile compositor setup”

This is how power users make it so:

* changing compositor takes <30 minutes
* configs don’t lock you into niri
* your workflow survives any ecosystem change

This is the holy grail of dotfiles architecture.
