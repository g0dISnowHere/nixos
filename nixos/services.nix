{ config, pkgs, ... }: {
  services = {
    syncthing.enable = true;
    # https://github.com/gmodena/nix-flatpak
    flatpak = {
      enable = true;
      # remotes = [{
      #   name = "flathub-beta";
      #   location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      # }];
      packages = [
        # TODO Add your desired Flatpak packages here
      ];
      update = {
        onActivation = true;
        auto = {
          enable = true;
          onCalendar = "weekly"; # Default value
        };
      };
    };

  };

  systemd.services.zigbee2mqtt = {
    description = "Zigbee2MQTT Service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.zigbee2mqtt_2}/bin/zigbee2mqtt --data /home/%u/.z2m";
      User = "djoolz";
      Restart = "on-failure";
    };
    preStart = ''
      mkdir -p /home/djoolz/.z2m
      chown djoolz /home/djoolz/.z2m
    '';
  };

  # Make zigbee2mqtt accessible through firewall
  networking.firewall.allowedTCPPorts = [
    8080
  ];

    # # Ensure the user exists (if not already defined elsewhere)
    # users.users.djoolz = {
    #   isNormalUser = true;
    #   home = "/home/djoolz";
    # };

  # services.octoprint = {
  #   enable = true;
  # };

}
