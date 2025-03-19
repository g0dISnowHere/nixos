{ config, pkgs, ... }:
{
  services = {
    # Enable flatpak support
    flatpak.enable = true;
    # enable the tailscale service
    # TODO needs an open firewall port
    tailscale.enable = true;
    };
    }