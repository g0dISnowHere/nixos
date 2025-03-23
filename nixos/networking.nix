{config, pkgs, ...}:
{
  ## https://nixos.wiki/wiki/Networking
  networking = {
    hostName = "karaka"; # Define your hostname.

    ## Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    ## Enable networking via networkmanager. Problematic with virt-manager.
    networkmanager = {
      enable = true;
      wifi.powersave = true;
      };

    ## https://nixos.wiki/wiki/wpa_supplicant
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # wireless.userControlled.enable = true; # Enables wireless support via wpa_supplicant with user-controlled configuration in GUI.

  };

  ## Fix for networkmanager-wait-online
  systemd.services.NetworkManager-wait-online = {
    serviceConfig = {
      ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];
    };
  };

  ## Some programs need SUID wrappers, can be configured further or are started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  ## List services that you want to enable:
}