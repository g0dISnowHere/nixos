## Security ideas in the same style

Think in terms of **small opt-in modules**, each with a clean option like:

```nix
site.security.ssh.enable = true;
site.security.auditd.enable = true;
site.security.secureBoot.enable = true;
site.security.serviceHardening.enable = true;
```

Then each module maps intent to concrete NixOS/systemd/kernel config.

---

# 1. Service hardening profile

This is probably the highest-value next idea.

NixOS/systemd services often run with broad privileges unless explicitly hardened. There is active NixOS discussion around tracking and improving systemd service hardening, because many services still lack confinement by default. ([GitHub][1])

Create a module that adds a reusable baseline for your own services:

```nix
systemd.services.my-service.serviceConfig = {
  NoNewPrivileges = true;
  PrivateTmp = true;
  PrivateDevices = true;
  ProtectSystem = "strict";
  ProtectHome = true;
  ProtectKernelTunables = true;
  ProtectKernelModules = true;
  ProtectControlGroups = true;
  RestrictSUIDSGID = true;
  RestrictRealtime = true;
  LockPersonality = true;
  MemoryDenyWriteExecute = true;
};
```

For network daemons:

```nix
RestrictAddressFamilies = [
  "AF_UNIX"
  "AF_INET"
  "AF_INET6"
];
```

For non-network daemons:

```nix
RestrictAddressFamilies = [ "AF_UNIX" ];
IPAddressDeny = "any";
```

Useful module API:

```nix
site.security.systemdHardening = {
  enable = true;
  defaultProfile = "moderate"; # minimal | moderate | strict
};
```

Do **not** globally harden every NixOS service at once. Apply to your own units first: Alloy, custom scripts, backup jobs, reverse proxies, mirror services, validators.

---

# 2. “Internet-capable service” classification

Make modules declare whether they are allowed to access the network.

Example:

```nix
site.services.backup.network = "egress-only";
site.services.generator.network = "none";
site.services.caddy.network = "ingress";
site.services.alloy.network = "egress-to-monitoring";
```

Then map this to:

```nix
IPAddressDeny = "any";
IPAddressAllow = [
  "10.0.0.0/8"
  "192.168.0.0/16"
];
RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
```

This fits your proxy/firewall/governance idea well: services should declare **why** they need network access.

---

# 3. NixOS Secure Boot via Lanzaboote

For NixOS, Lanzaboote is the common path for Secure Boot with a custom keychain. Its own docs warn that it is for experienced NixOS users and has sharp edges; a bad setup can leave a system unbootable without recovery tools. ([nix-community.github.io][2])

Good module idea:

```nix
site.security.secureBoot = {
  enable = true;
  mode = "lanzaboote";
};
```

But I would gate it hard:

```nix
assertions = [
  {
    assertion = config.site.security.secureBoot.enable
      -> config.site.recovery.hasTestedUsb;
    message = "Secure Boot requires tested recovery media.";
  }
];
```

For your systems, I’d do this only after your boot/recovery workflow is solid.

---

# 4. Secrets discipline with `sops-nix`

Pattern:

```nix
site.security.secrets.enable = true;
site.security.secrets.backend = "sops-nix";
```

Rules:

* no plaintext secrets in repo
* no `.env` with real credentials
* SSH host keys persisted before decrypting host secrets
* separate secrets by host/profile
* monitoring configs should not need secrets in Phase 1

This becomes more important if you combine **impermanence + sops-nix + Secure Boot**, because persisted host keys and signing keys have to be handled deliberately. A recent NixOS setup writeup notes that impermanence, sops-nix, and Lanzaboote become interdependent: persisted SSH keys are needed for sops-nix decryption, and persisted Secure Boot signing keys are needed for Lanzaboote. ([Haseeb Majid][3])

---

# 5. Impermanence / ephemeral root

Security-relevant idea: make the OS mostly disposable.

Pattern:

```nix
site.persistence.enable = true;
site.persistence.paths = [
  "/var/lib/nixos"
  "/var/lib/systemd"
  "/var/log"
  "/etc/ssh"
  "/etc/secureboot"
];
```

Benefits:

* unknown local modifications disappear on reboot
* easier drift detection
* clearer list of what state actually matters
* pairs well with declarative NixOS

Risk:

* if you forget to persist something important, you lose it
* annoying until mature
* dangerous with secret management unless planned

I’d test this on a non-critical machine first.

---

# 6. Audit policy as a module, not raw audit rules

Instead of dumping auditd rules inline, define intent:

```nix
site.security.audit = {
  enable = true;
  watchFirewall = true;
  watchUsers = true;
  watchSudo = true;
  watchSsh = true;
  logEveryExec = false;
};
```

Good watches:

```text
/etc/nftables.conf
/etc/nftables.d/
/etc/ssh/sshd_config
/etc/passwd
/etc/group
/etc/shadow
/etc/sudoers
/etc/sudoers.d/
```

Avoid at first:

```text
log all execve
```

That is high-volume and will pollute Loki/Prometheus unless you have a clear query and retention story.

Better for your monitoring stack:

* alert when firewall config changes
* alert when SSH config changes
* alert when sudoers changes
* alert when a new UID 0 user appears
* alert when audit logs stop arriving

---

# 7. Kernel hardening split into tiers

Do not make one giant “secure kernel” module. Split it:

```nix
site.security.kernel = {
  baseline.enable = true;
  networkHardening.enable = true;
  lockdown.enable = false;
  moduleBlacklist.enable = true;
  debugRestrictions.enable = true;
};
```

### Safe-ish baseline

```nix
boot.kernel.sysctl = {
  "kernel.dmesg_restrict" = 1;
  "kernel.kptr_restrict" = 2;
  "kernel.yama.ptrace_scope" = 2;
  "kernel.sysrq" = 0;
  "fs.protected_symlinks" = 1;
  "fs.protected_hardlinks" = 1;
  "fs.protected_fifos" = 2;
  "fs.protected_regular" = 2;
};
```

### Riskier tier

```nix
boot.kernelParams = [
  "lockdown=confidentiality"
  "module.sig_enforce=1"
];
```

Only use after checking NVIDIA, virtualization, debugging tools, eBPF/perf, and recovery.

---

# 8. SSH as a strict profile

Good reusable module:

```nix
site.security.ssh = {
  enable = true;
  passwordLogin = false;
  rootLogin = false;
  allowUsers = [ "julian" ];
  tailscaleOnly = true;
};
```

Map to:

```nix
services.openssh.settings = {
  PermitRootLogin = "no";
  PasswordAuthentication = false;
  KbdInteractiveAuthentication = false;
  X11Forwarding = false;
};
```

If `tailscaleOnly = true`, bind SSH to Tailscale or firewall it:

```nix
networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
```

This is more valuable than exotic kernel hardening.

---

# 9. Firewall policy as data

Instead of random `allowedTCPPorts`, define named services:

```nix
site.firewall.allowedServices = {
  ssh = {
    port = 22;
    interfaces = [ "tailscale0" ];
  };

  prometheusNode = {
    port = 9100;
    interfaces = [ "monitoring" ];
  };

  alloy = {
    port = 12345;
    interfaces = [ "monitoring" ];
  };
};
```

Then generate NixOS firewall rules.

This prevents “mystery open port 3000” configs.

Also generate a textfile metric:

```text
site_expected_open_port{host="dreapc142",service="ssh",port="22"} 1
```

Then your monitoring can detect drift.

---

# 10. Drift detection for security-relevant config

Because NixOS is declarative, drift should be suspicious.

Watch:

```text
/etc/nixos
/etc/ssh
/etc/sudoers*
/etc/nftables*
/etc/systemd/system
/var/lib/tailscale
```

Emit:

```text
security_config_changed{host="dreapc142",path="/etc/ssh/sshd_config"} 1
```

Or better: logs to Loki with clean labels:

```text
host="dreapc142"
source="auditd"
event="security_config_changed"
target="ssh"
```

No raw audit noise in labels.

---

# 11. “Expected security posture” metrics

Very aligned with your Grafana expectations.

Generate per host:

```text
security_expected_auditd_enabled{host="dreapc142"} 1
security_expected_firewall_enabled{host="dreapc142"} 1
security_expected_ssh_password_auth_disabled{host="dreapc142"} 1
security_expected_tailscale_enabled{host="dreapc142"} 1
security_expected_secureboot_enabled{host="dreapc142"} 0
```

And actual:

```text
security_actual_auditd_enabled{host="dreapc142"} 1
security_actual_firewall_enabled{host="dreapc142"} 1
security_actual_ssh_password_auth_disabled{host="dreapc142"} 1
```

Then dashboard panels can say:

```text
all security checks passing
```

or:

```text
missing: auditd on dreapc130
wrong: ssh password auth enabled on dreapc133
```

This is better than visually inspecting raw labels.

---

# 12. Separate profiles: workstation, server, lab, laptop

Example:

```nix
site.profiles.workstation.security = {
  apparmor = true;
  firewall = true;
  auditd = "light";
  earlyoom = true;
  secureBoot = false;
};

site.profiles.server.security = {
  apparmor = true;
  firewall = true;
  auditd = "medium";
  fail2ban = true;
  ssh = "strict";
};

site.profiles.lab.security = {
  firewall = true;
  auditd = "light";
  allowDebugging = true;
};
```

This avoids the usual problem: hardening modules become too strict for dev machines and then get disabled everywhere.

---

# 13. AppArmor profile with kill switch

Useful API:

```nix
site.security.apparmor = {
  enable = true;
  enforce = true;
  killUnconfinedConfinable = false;
};
```

Do not default to killing processes. Make that a stricter mode.

```nix
site.security.apparmor.mode = "complain" | "enforce" | "strict";
```

Start with `complain` or standard profiles.

---

# 14. Package/source restrictions

Security-relevant Nix policy:

```nix
site.nix.policy = {
  allowUnfree = true;
  allowBroken = false;
  allowInsecure = false;
  permittedInsecurePackages = [ ];
};
```

Then assert:

```nix
assertions = [
  {
    assertion = config.nixpkgs.config.permittedInsecurePackages == [];
    message = "Insecure packages must be explicitly justified.";
  }
];
```

Also useful:

```nix
nix.settings.allowed-users = [ "@wheel" ];
nix.settings.trusted-users = [ "root" "@wheel" ];
```

For a company/dev fleet, be careful with who gets `trusted-users`; it is effectively very powerful.

---

# 15. “Break glass” recovery profile

Security hardening without recovery is fragile.

Create a special boot profile:

```nix
site.recovery.enable = true;
```

It should:

* enable password login only locally if needed
* disable strict lockdown
* keep SSH available on trusted interface
* include debugging tools
* keep logs accessible
* maybe disable graphical target

For example:

```nix
specialisation.recovery.configuration = {
  site.security.kernel.lockdown.enable = false;
  site.security.auditd.enable = false;
  services.openssh.enable = true;
};
```

This would have helped in your recent NixOS boot-debug situation.

---

## My recommended priority order

### Do first

1. **Systemd service hardening for your own services**
2. **Strict SSH profile**
3. **Firewall policy as data**
4. **Audit rules for config changes**
5. **Security posture textfile metrics**
6. **Break-glass recovery specialization**

### Do later

7. AppArmor profiles
8. Impermanence
9. sops-nix everywhere
10. Secure Boot / Lanzaboote
11. Kernel lockdown
12. Full egress governance

### Avoid for now

* global aggressive kernel lockdown
* blanket audit `execve`
* passwordless sudo
* globally hardening all systemd units without testing
* copying someone else’s TCP/kernel tuning wholesale

[1]: https://github.com/NixOS/nixpkgs/issues/377827?utm_source=chatgpt.com "Tracking: systemd hardening in NixOS · Issue #377827"
[2]: https://nix-community.github.io/lanzaboote/?utm_source=chatgpt.com "Introduction"
[3]: https://haseebmajid.dev/posts/2025-12-31-how-to-setup-a-new-pc-with-lanzaboote-tpm-decryption-sops-nix-impermanence-nixos-anywhere?utm_source=chatgpt.com "How to Setup a New PC With Lanzaboote, TPM Decryption ..."
