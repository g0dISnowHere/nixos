{ pkgs, ... }:
{
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    extraUpFlags = [ "--accept-routes" ];
  };

  networking.firewall.allowedUDPPorts = [ 41641 ];
}
