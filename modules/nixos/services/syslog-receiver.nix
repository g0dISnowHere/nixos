{
  config,
  lib,
  ...
}:
let
  cfg = config.my.syslogReceiver;
in
{
  options.my.syslogReceiver = {
    enable = lib.mkEnableOption "LAN UDP syslog receiver";

    allowedIPv4Sources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "IPv4 addresses permitted to submit UDP syslog.";
    };
  };

  # Receive remote syslog (UDP 514) and write to /var/log/remote/<hostname>/
  # Used for collecting OpenWrt router logs on the LAN.

  config = lib.mkIf cfg.enable {
    services.rsyslogd = {
      enable = true;
      defaultConfig = "";
      extraConfig = ''
        # Load UDP syslog input
        module(load="imudp")
        input(type="imudp" port="514")

        # Dynamic file path template (must precede rules that reference it)
        template(name="remoteSyslog" type="string"
          string="/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log")

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
      '';
    };

    networking.firewall.extraInputRules = lib.concatMapStringsSep "\n" (
      source: "ip saddr ${source} udp dport 514 accept"
    ) cfg.allowedIPv4Sources;

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
  };
}
