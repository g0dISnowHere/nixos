{ pkgs, ... }: {
  systemd.services.zigbee2mqtt = {
    description = "Zigbee2MQTT Service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart =
        "${pkgs.zigbee2mqtt_2}/bin/zigbee2mqtt --data /home/djoolz/.z2m";
      User = "djoolz";
      Restart = "on-failure";
    };
    preStart = ''
      mkdir -p /home/djoolz/.z2m
      chown djoolz /home/djoolz/.z2m
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
