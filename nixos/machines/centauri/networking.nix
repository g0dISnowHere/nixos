{ config, pkgs, ... }: {

  # Fix for networkmanager-wait-online
  systemd.services.NetworkManager-wait-online = {
    serviceConfig = {
      ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];
    };
  };

  # https://nixos.wiki/wiki/Networking
  networking = {
    # hostName = "centauri"; # Define your hostname.
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable networking
    networkmanager.enable = true;
    # networkmanager.unmanaged = [ "wlp0s20f0u2" ]; # For using the USB WiFi dongle with cli tools.

    # Prevent NetworkManager from managing bridge interfaces
    # networkmanager.unmanaged = [ "br0" "enp0s31f6" ];
  };

}
