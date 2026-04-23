{ lib, ... }: {
  # Homelab Role Profile
  # Transitional server-like profile. Prefer explicit capability imports in new
  # machine definitions.

  imports = [
    ../system/base.nix
    ../services/ssh-server.nix
    ../services/tailscale-router.nix
  ];

  networking.networkmanager.enable = lib.mkDefault true;
}
