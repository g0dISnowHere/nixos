{ config, pkgs, ... }: {
  # GSConnect Module - Self-Contained
  # Provides installation of GNOME GSConnect extension and KDE Connect backend,
  # along with necessary firewall rules for communication.

  # Install the GSConnect extension
  environment.systemPackages = with pkgs; [ gnomeExtensions.gsconnect ];

  # Enable KDE Connect (backend for GSConnect)
  programs.kdeconnect = {
    enable = true;
    package =
      pkgs.kdePackages.kdeconnect-kde; # Use the correct KDE Connect package
  };

  # Firewall rules for KDE Connect communication
  networking.firewall.allowedTCPPortRanges = [{
    from = 1714;
    to = 1764;
  }];
  networking.firewall.allowedUDPPortRanges = [{
    from = 1714;
    to = 1764;
  }];
}
