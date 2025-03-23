# https://nixos.wiki/wiki/SSH
{ config, pkgs, ... }:
{
  ## This setups a SSH server. Very important if you're setting up a headless system.
  ## Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      ## a list of options: https://search.nixos.org/options?show=services.openssh
      ## Opinionated: forbid root login through SSH.
      ## Opinionated: use keys only. Remove if you want to SSH using passwords.
      PasswordAuthentication = true;  
      AllowUsers = ["djoolz"]; # null allows all users by default. Can be [ null ] or [ "user1" "user2" ]
      # UseDns = true;
      PermitRootLogin = "yes"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"  
      ## For forwarding X11 through ssh
      X11Forwarding = true; # This is for receiving X11 from the server.
      AllowTCPForwarding = true;
      PermitTunnel = "yes"; # "yes", "point-to-point", "ethernet", "no"
      X11DisplayOffset = 10; # To make sure another session than the local one is used.
      X11UseLocalhost = "yes";
      };
    };

  ## Open the appropriate ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 
    22
    ];

  # users.users.djoolz.
  ## This setups a SSH client.
  # programs.openssh = {
  #   enable = true;
  #   settings = {
  #     ## Opinionated: use keys only. Remove if you want to SSH using passwords.
  #     PasswordAuthentication = true;
  #     };
  #   };
  }