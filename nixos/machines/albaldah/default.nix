{ ... }: {
  # STRATO VPS
  # Remote x86_64 server currently documented under vps docs/
  # Role: headless VPS with SSH, Tailscale, and container workloads

  imports = [
    ./hardware-configuration.nix
    ./firewall.nix
    ./provider-networking.nix
    ./boot.nix
    ./docker-compose-secrets.nix
    ../../../modules/nixos/system/autoupgrade.nix
  ];

  users.users.djoolz = {
    extraGroups = [ "wheel" ];
  };

  # Home Manager configuration for this machine.
  home-manager.users.djoolz = {
    imports = [ ../../../flake/homes/users/djoolz/server.nix ];
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
