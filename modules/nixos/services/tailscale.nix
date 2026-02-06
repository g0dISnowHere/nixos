{ config, pkgs, ... }: {
  # Tailscale VPN Service
  # Provides secure mesh VPN networking with firewall configuration for Tailscale port

  # enable the tailscale service using the tailscale-specific nixpkgs version
  services.tailscale = {
    enable = true;
    # package = pkgs-tailscale.tailscale;
    package = pkgs.tailscale;
  };

  # networking.nftables.enable = true; ## https://nixos.wiki/wiki/Tailscale
  networking.firewall.allowedUDPPorts = [
    41641 # https://fzakaria.com/2020/09/17/tailscale-is-magic-even-more-so-with-nixos.html
  ];

  # environment.systemPackages = with pkgs; [ tailscale ];

}
