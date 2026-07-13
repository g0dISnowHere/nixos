{ inputs, ... }: {
  # Albaldah - public-edge x86_64 host
  # Remote administration uses Tailscale SSH and container workloads.

  imports = [
    ./hardware-configuration.nix
    ./firewall.nix
    ./provider-networking.nix
    ./boot.nix
    ./docker-compose-secrets.nix
    ../../../modules/nixos/system/autoupgrade.nix
    ../../../modules/nixos/system/home-manager.nix
    ../../../modules/nixos/system/base.nix
    ../../../modules/nixos/system/ai-tools.nix
    ../../../modules/nixos/system/developer-tools.nix
    ../../../modules/nixos/services/monitoring-baseline.nix
    ../../../modules/nixos/services/vscode-remote.nix
    ../../../modules/nixos/services/crowdsec.nix
    ../../../modules/nixos/services/tailscale-client.nix
    ../../../modules/nixos/virtualisation/docker.nix
    inputs.disko.nixosModules.disko
    ../../../modules/nixos/system/disko-install-test-compat.nix
    ./disko.nix
  ];

  users.users.djoolz = {
    extraGroups = [ "wheel" ];
  };

  # Home Manager configuration for this machine.
  home-manager.users.djoolz = {
    imports = [ ../../../flake/homes/users/djoolz/base.nix ];
    # Do not change casually. See docs/architecture/state-version-reasons.md.
    home.stateVersion = "25.11";
  };

  security.audit.backlogLimit = 8192;

  my.autoUpdate = {
    enable = true;
    mode = "updater";
    onCalendar = "weekly";
  };

  my.tailscale = {
    enableSSH = true;
    advertiseExitNode = true;
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
