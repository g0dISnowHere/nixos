{ config, pkgs, ... }:
{
  services = {
    # Enable flatpak support
    # flatpak.enable = true;
    # enable the tailscale service
    # TODO needs an open firewall port
    tailscale.enable = true;
    };

  networking.firewall = {
    allowedTCPPorts = [ 24800 22000 ]; # One of these ports is for barrier.
    };

  ## Make sure this works with home-manager!
  users.users.djoolz.extraGroups = [ "tailscale" ]; # doesn't yet work, set in config or users.nix

  }