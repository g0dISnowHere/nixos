# https://nixos.wiki/wiki/Docker
{ config,
  pkgs,
  ... }:
{
  virtualisation.docker = {
    enable = true;
    # autoprune = {
    #   enable = true;
    #   dates = "weekly";
    # };
    # rootless = {
    #   enable = true;
    #   setSocketVariable = true;
    # };
  };
  ## Make sure this works with home-manager!
  users.users.djoolz.extraGroups = [ "docker" ]; # doesn't yet work, set in config or users.nix
}