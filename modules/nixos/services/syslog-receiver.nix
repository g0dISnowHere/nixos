_: {
  # Receive remote syslog (UDP 514) and write to /var/log/remote/<hostname>/
  # Used for collecting OpenWrt router logs on the LAN.

  services.rsyslogd = {
    enable = true;
    defaultConfig = "";
    extraConfig = ''
      # Load UDP syslog input
      module(load="imudp")
      input(type="imudp" port="514")

      # Remote hosts -> /var/log/remote/<hostname>/<programname>.log
      # Local messages stay in journald; rsyslog only handles remote.
      if $fromhost-ip != "127.0.0.1" then {
        action(
          type="omfile"
          dynaFile="remoteSyslog"
          template="RSYSLOG_TraditionalFileFormat"
          createDirs="on"
          dirCreateMode="0755"
          fileCreateMode="0644"
        )
        stop
      }

      template(name="remoteSyslog" type="string"
        string="/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log")
    '';
  };

  # Open UDP 514 for syslog reception
  networking.firewall.allowedUDPPorts = [ 514 ];

  # Rotate remote logs: 7-day retention, compress after 1 day
  services.logrotate.settings.remote-syslog = {
    files = "/var/log/remote/*/*.log";
    frequency = "daily";
    rotate = 7;
    compress = true;
    delaycompress = true;
    missingok = true;
    notifempty = true;
    create = "0644 root root";
    sharedscripts = true;
    postrotate = "systemctl reload rsyslog.service > /dev/null 2>&1 || true";
  };
}
