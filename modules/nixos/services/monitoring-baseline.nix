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

        # High-volume execve auditing is intentionally omitted here: logging
        # every root/user command turns a baseline into unbounded log churn.
        "-a always,exit -F arch=b64 -S init_module,finit_module,delete_module -k kernel_modules"
        "-a always,exit -F arch=b64 -S openat,creat,truncate,ftruncate -F exit=-EACCES -k access_denied"
        "-a always,exit -F arch=b64 -S openat,creat,truncate,ftruncate -F exit=-EPERM -k access_denied"
        "-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time_change"
        "-a always,exit -F arch=b64 -S sethostname,setdomainname -k hostname_change"
      ];
    };

    auditd = {
      enable = true;

      # auditd writes outside journald, so give it its own hard cap. Without an
      # explicit cap, noisy rules can fill /var/log/audit before journald limits
      # matter.
      settings = {
        max_log_file = 256;
        num_logs = 8;
        max_log_file_action = "rotate";
        disk_full_action = "rotate";
        space_left = 2048;
        space_left_action = "syslog";
        admin_space_left = 1024;
        admin_space_left_action = "single";
      };
    };
  };

}
