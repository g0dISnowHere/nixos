{
  hostname,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./firewall.nix
    inputs.nixos-wsl.nixosModules.default
  ];

  networking.hostName = hostname;

  wsl = {
    enable = true;
    defaultUser = "djoolz";
    startMenuLaunchers = true;
  };

  # Hardware configuration for NVIDIA GPU support in containers
  hardware.nvidia-container-toolkit = {
    enable = true;
    suppressNvidiaDriverAssertion = true; # Suppress assertion since NVIDIA driver is provided by WSL/Windows host
  };

  users.users.djoolz.extraGroups = [ "wheel" ];

  # Home Manager configuration for this machine.
  home-manager.users.djoolz = {
    imports = [ ../../../flake/homes/users/djoolz/server.nix ];
    # Do not change casually. See docs/architecture/state-version-reasons.md.
    home.stateVersion = "25.11";
  };

  my.tailscale.enableSSH = true;

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = lib.mkDefault "25.11";
}
