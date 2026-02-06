{ config, lib, ... }:

let
  username = "djoolz";
  homeDir =
    lib.attrByPath [ "users" "users" username "home" ] "/home/${username}"
    config;
  flakePath = "${homeDir}/Documents/01_config/mine";
in {
  # https://nixos.wiki/wiki/Automatic_system_upgrades
  # Automatic upgrades, pointing at the locally maintained flake.
  # system.autoUpgrade = {
  #   enable = true;
  #   allowReboot = true;
  #   flake = "${flakePath}#${config.networking.hostName}";
  #   flags = [
  #     "flake update"
  #     "nixpkgs"
  #     # "--commit-lock-file"
  #     "-L" # print build logs
  #   ];
  #   dates = "9:05";
  #   randomizedDelaySec = "45min";
  # };

  # Also enable garbage collection of old generations.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };

  # Enable automatic nix-store optimisation.
  nix.optimise = {
    automatic = true;
    # dates = [ "12:45" ]; # Optional; allows customizing optimisation schedule
  };
}
