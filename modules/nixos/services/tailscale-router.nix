{ ... }: {
  imports = [ ./tailscale.nix ];

  # Host may advertise subnet or exit routes via host-specific config.
  # Keep this module minimal so it does not force routing behavior on every host.
  my.tailscale = { };
}
