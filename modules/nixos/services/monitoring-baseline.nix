_: {
  services = {
    prometheus.exporters = {
      node = {
        enable = true;
        port = 9100;
        listenAddress = "127.0.0.1";
      };

      systemd = {
        enable = true;
        port = 9558;
        listenAddress = "127.0.0.1";
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
  };

}
