{ lib, pkgs, ... }:
let
  dockerIngressCidrs =
    [ "172.17.0.0/16" "172.30.0.0/16" "172.31.0.0/16" "172.32.0.0/16" ];
  dockerIngressInterfaces = [ "docker0" "br-*" ];
in {
  # STRATO VPS
  # Remote x86_64 server currently documented under vps docs/
  # Role: headless VPS with SSH, Tailscale, and container workloads

  imports = [
    ./hardware-configuration.nix
    ./provider-networking.nix
    ./boot.nix
    ./docker-compose-secrets.nix
    ../../../modules/nixos/system/autoupgrade.nix
  ];

  users.users.djoolz = { extraGroups = [ "wheel" ]; };

  environment.systemPackages = with pkgs; [ curl git htop tmux vim ];

  security.audit = {
    enable = true;
    rules = [
      "-w /etc/passwd -p wa -k identity"
      "-w /etc/group -p wa -k identity"
      "-w /etc/shadow -p wa -k identity"
      "-w /etc/gshadow -p wa -k identity"
      "-w /etc/sudoers -p wa -k sudoers"
      "-w /etc/sudoers.d/ -p wa -k sudoers"
      "-w /root/.ssh/ -p wa -k root_ssh"
      "-w /etc/systemd/system/ -p wa -k systemd_units"
      "-w /run/systemd/system/ -p wa -k systemd_runtime_units"
      "-w /etc/cron.d/ -p wa -k cron"
      "-w /etc/cron.daily/ -p wa -k cron"
      "-w /etc/crontab -p wa -k cron"
      "-w /etc/nixos/ -p wa -k nixos_config"
      "-w /home/djoolz/docker/ -p wa -k docker_compose"
      "-a always,exit -F arch=b64 -S execve -F euid=0 -k root_exec"
      "-a always,exit -F arch=b64 -S execve -F auid>=1000 -F auid!=unset -k user_exec"
      "-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k kernel_modules"
      "-a always,exit -F arch=b64 -S openat,creat,truncate,ftruncate -F exit=-EACCES -k access_denied"
      "-a always,exit -F arch=b64 -S openat,creat,truncate,ftruncate -F exit=-EPERM -k access_denied"
      "-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time_change"
      "-a always,exit -F arch=b64 -S sethostname,setdomainname -k hostname_change"
    ];
  };
  security.auditd.enable = true;
  services.journald.audit = true;

  services.prometheus.exporters = {
    node.listenAddress = lib.mkForce "0.0.0.0";
    systemd.listenAddress = lib.mkForce "0.0.0.0";
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];

    extraInputRules = lib.mkAfter ''
      ip saddr { ${
        lib.concatStringsSep ", " dockerIngressCidrs
      } } tcp dport { 9100, 9558 } accept comment "allow Docker monitoring stack to reach host exporters"
      iifname { ${
        lib.concatStringsSep ", "
        (map (iface: ''"${iface}"'') dockerIngressInterfaces)
      } } tcp dport { 9100, 9558 } accept comment "allow Docker bridge interfaces to reach host exporters"
    '';

    extraCommands = lib.mkAfter ''
      ${lib.concatMapStringsSep "\n" (cidr: ''
        iptables -C nixos-fw -s ${cidr} -p tcp -m multiport --dports 9100,9558 -j nixos-fw-accept 2>/dev/null \
          || iptables -I nixos-fw 3 -s ${cidr} -p tcp -m multiport --dports 9100,9558 -j nixos-fw-accept
      '') dockerIngressCidrs}
    '';

    extraStopCommands = lib.mkAfter ''
      ${lib.concatMapStringsSep "\n" (cidr: ''
        iptables -D nixos-fw -s ${cidr} -p tcp -m multiport --dports 9100,9558 -j nixos-fw-accept 2>/dev/null || true
      '') dockerIngressCidrs}
    '';
  };

  my.autoUpdate = {
    enable = true;
    mode = "updater";
    onCalendar = "weekly";
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
