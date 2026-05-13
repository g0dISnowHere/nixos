_: {
  services.prometheus.exporters = {
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

  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=7day
  '';
}
