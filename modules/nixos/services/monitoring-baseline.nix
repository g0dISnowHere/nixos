_: {
  services = {
    prometheus.exporters = {
      node = {
        enable = true;
        port = 9100;
        listenAddress = "0.0.0.0";
        openFirewall = false;
      };

      systemd = {
        enable = true;
        port = 9558;
        listenAddress = "0.0.0.0";
        openFirewall = false;
      };
    };
    journald.audit = true;

    journald.extraConfig = ''
      SystemMaxUse=1G
      MaxRetentionSec=7day
    '';
  };

  security = {
    audit = {
      enable = true;
      rules = [
        # Core identity/account files.
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/group -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
        "-w /etc/gshadow -p wa -k identity"

        # Privilege escalation and root access surfaces.
        "-w /etc/sudoers -p wa -k sudoers"
        "-w /etc/sudoers.d/ -p wa -k sudoers"
        "-w /root/.ssh/ -p wa -k root_ssh"

        # Service/unit and scheduled-task definitions.
        "-w /etc/systemd/system/ -p wa -k systemd_units"
        "-w /run/systemd/system/ -p wa -k systemd_runtime_units"
        "-w /etc/cron.d/ -p wa -k cron"
        "-w /etc/cron.daily/ -p wa -k cron"
        "-w /etc/crontab -p wa -k cron"

        # NixOS and firewall configuration state.
        "-w /etc/nixos/ -p wa -k nixos_config"
        "-w /etc/nftables.conf -p wa -k firewall_config"
        "-w /etc/nftables/ -p wa -k firewall_config"
        "-w /etc/iptables/ -p wa -k firewall_config"

        # Docker runtime/config and compose project path.
        "-w /etc/docker/ -p wa -k docker_config"
        "-w /run/docker.sock -p wa -k docker_sock"
        "-w /home/djoolz/docker/ -p wa -k docker_compose"

        # Execution and syscall activity of interest.
        "-a always,exit -F arch=b64 -S execve -F euid=0 -k root_exec"
        "-a always,exit -F arch=b64 -S execve -F auid>=1000 -F auid!=unset -k user_exec"
        "-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k kernel_modules"
        "-a always,exit -F arch=b64 -S openat,creat,truncate,ftruncate -F exit=-EACCES -k access_denied"
        "-a always,exit -F arch=b64 -S openat,creat,truncate,ftruncate -F exit=-EPERM -k access_denied"
        "-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time_change"
        "-a always,exit -F arch=b64 -S sethostname,setdomainname -k hostname_change"
      ];
    };

    auditd.enable = true;
  };

}
