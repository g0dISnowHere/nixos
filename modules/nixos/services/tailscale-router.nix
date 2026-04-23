{ lib, ... }: {
  imports = [ ./tailscale.nix ];

  my.tailscale = {
    enableSSH = lib.mkDefault true;
    advertiseExitNode = lib.mkDefault true;
  };
}
