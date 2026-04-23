{ lib, ... }: {
  imports = [ ./tailscale.nix ];

  my.tailscale = {
    enableSSH = lib.mkDefault false;
    acceptRoutes = lib.mkDefault true;
  };
}
