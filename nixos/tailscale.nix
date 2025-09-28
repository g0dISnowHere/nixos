{ config, pkgs, ... }: {

  # enable the tailscale service
  services.tailscale.enable = true;

  # networking.nftables.enable = true; ## https://nixos.wiki/wiki/Tailscale
  networking.firewall.allowedUDPPorts = [
    41641 # https://fzakaria.com/2020/09/17/tailscale-is-magic-even-more-so-with-nixos.html
  ];

  # environment.systemPackages = with pkgs; [ tailscale ];

}
