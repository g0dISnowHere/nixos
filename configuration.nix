# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

## TODO if stable: delete directories /nix/var/nix/profiles/per-user/root/channels_bak and /root/.nix-defexpr/channels_bak

{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # TODO: Modify other-hardware.nix
    ./nixos/autoupgrade.nix
    # ./nixos/docker.nix
    ./nixos/bootloader.nix
    # TODO: Open the appropriate ports in the firewall. A few are necessary.
    ./nixos/firewall.nix
    ./nixos/flatpak.nix
    ./nixos/locale.nix
    ./nixos/networking.nix
    ./nixos/hardware-configuration.nix
    # ./nixos/packages.nix
    # ./nixos/other-hardware.nix
    # ./nixos/plasma.nix
    ./nixos/gnome.nix
    # ./nixos/podman.nix
    # ./nixos/homeassistant.nix
    ./nixos/scanner.nix
    # TODO: Modify ssh.nix
    ./nixos/ssh.nix
    # TODO: Modify users.nix
    ./nixos/tailscale.nix
    ./nixos/users.nix
    ./virt-manager/virtualisation.nix
  ];

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry - Why?
      flake-registry = "";

      # Workaround for https://github.com/NixOS/nix/issues/9574
      # TODO: Still relevant https://github.com/NixOS/nix/pull/11079
      nix-path = config.nix.nixPath;

      ## optimise store after every build.
      # https://nixos.wiki/wiki/Storage_optimization
      auto-optimise-store = true;
    };

    ## optimise store on a schedule.
    # https://nixos.wiki/wiki/Storage_optimization
    # optimise = {
    #   automatic = true;
    #   dates = [ "03:45" ]; # Optional; allows customizing optimisation schedule
    # };

    # garbage collection https://nixos.wiki/wiki/Storage_optimization
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 10d";
    };
    
    # Opinionated: disable channels
    # Why? -> to prevent using instable channels
    channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
