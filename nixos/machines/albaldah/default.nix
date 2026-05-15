{ pkgs, ... }: {
  # STRATO VPS
  # Remote x86_64 server currently documented under vps docs/
  # Role: headless VPS with SSH, Tailscale, and container workloads

  imports = [
    ./hardware-configuration.nix
    ./provider-networking.nix
    ./boot.nix
    ./docker-compose-secrets.nix
    ../../../modules/nixos/system/autoupgrade.nix
  ];

  users.users.djoolz = { extraGroups = [ "wheel" ]; };

  environment.systemPackages = with pkgs; [ curl git htop tmux vim ];

  networking.firewall = { allowedTCPPorts = [ 80 443 ]; };

  my.autoUpdate = {
    enable = true;
    mode = "updater";
    onCalendar = "weekly";
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
