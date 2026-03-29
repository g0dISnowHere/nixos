{ config, lib, pkgs, ... }:
let
  cfg = config.my.tailscale;
  extraUpFlags = lib.optionals cfg.enableSSH [ "--ssh" ]
    ++ lib.optionals cfg.advertiseExitNode [ "--advertise-exit-node" ]
    ++ lib.optionals (cfg.advertiseRoutes != [ ])
    [ "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}" ]
    ++ lib.optionals cfg.acceptRoutes [ "--accept-routes" ];
  needsForwarding = cfg.advertiseExitNode || cfg.advertiseRoutes != [ ];
in {
  # Tailscale VPN Service
  # Provides secure mesh VPN networking with per-role/per-host routing behavior.

  options.my.tailscale = {
    enableSSH = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Tailscale SSH on this host.";
    };

    advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Advertise this host as a Tailscale exit node.";
    };

    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "192.168.3.0/24" ];
      description = "Subnet routes this host should advertise to the tailnet.";
    };

    acceptRoutes = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Accept subnet routes advertised by other Tailscale nodes.";
    };
  };

  config = {
    # enable the tailscale service using the tailscale-specific nixpkgs version
    services.tailscale = {
      enable = true;
      package = pkgs.tailscale;
      extraUpFlags = extraUpFlags;
    };

    # networking.nftables.enable = true; ## https://nixos.wiki/wiki/Tailscale
    networking.firewall.allowedUDPPorts = [
      41641 # https://fzakaria.com/2020/09/17/tailscale-is-magic-even-more-so-with-nixos.html
    ];

    boot.kernel.sysctl = lib.mkIf needsForwarding {
      "net.ipv4.ip_forward" = lib.mkDefault 1;
      "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;
    };

    # environment.systemPackages = with pkgs; [ tailscale ];
  };
}
