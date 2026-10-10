{ lib, hostname, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/system/base.nix
    ../../../modules/nixos/system/home-manager.nix
    ../../../modules/nixos/system/ai-tools.nix
    ../../../modules/nixos/system/developer-tools.nix
    ../../../modules/nixos/services/ssh-server.nix
    ../../../modules/nixos/services/tailscale-base.nix
    ../../../modules/nixos/services/tailscale-ssh.nix
    ../../../modules/nixos/services/tailscale-exit-node.nix
    ../../../modules/nixos/services/tailscale-subnet-router.nix
    ../../../modules/nixos/services/flatpak.nix
    ../../../modules/nixos/desktop/gnome.nix
    ../../../modules/nixos/desktop/gnome-local-admin.nix
    ../../../modules/nixos/services/monitoring-baseline.nix
    ../../../modules/nixos/services/monitoring-alloy.nix
    ../../../modules/nixos/virtualisation/docker.nix
    ./pangolin-newt.nix
  ];

  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  my.monitoring = {
    enable = true;
    site = "home";
  };

  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };
  boot.resumeDevice = "/dev/disk/by-label/swap";

  services.tailscale.extraUpFlags = lib.mkForce [
    "--ssh"
    "--advertise-exit-node"
  ];

  users.users.djoolz.extraGroups = [
    "networkmanager"
    "wheel"
    "scanner"
    "lp"
  ];

  home-manager.users.djoolz = {
    imports = [ ../../../flake/homes/users/djoolz/karaka.nix ];
    home.stateVersion = "24.05";
  };

  services.flatpak.packages = lib.mkForce [];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  system.stateVersion = "24.11";
}
