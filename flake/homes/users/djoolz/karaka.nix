{ pkgs, ... }:
{
  imports = [
    ../../profiles/base.nix
    ./personal.nix
  ];

  home.packages = with pkgs; [
    syncthing
  ];

  services.syncthing.enable = true;
}
