{ lib, hostname, ... }: {
  networking = {
    hostName = hostname;
    firewall.enable = true;

    # This VPS should stay on provider-style networkd + DHCP for remote
    # reliability.
    networkmanager.enable = false;
    useDHCP = lib.mkDefault false;
    enableIPv6 = true;
  };

  systemd = {
    network = {
      enable = true;
      wait-online.anyInterface = true;
      networks."10-ens6" = {
        matchConfig.Name = "ens6";
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };

    services."getty@tty1".enable = true;
    services."serial-getty@ttyS0".enable = true;
  };

  services.resolved.enable = true;
}
