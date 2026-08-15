{ lib, ... }: {
  imports = [
    ../../../modules/nixos/services/tailscale.nix
  ];

  my.tailscale = {
    enableSSH = lib.mkDefault false;
    acceptRoutes = lib.mkDefault true;
    advertiseRoutes = lib.mkDefault [ "192.168.3.0/24" ];
  };
}
