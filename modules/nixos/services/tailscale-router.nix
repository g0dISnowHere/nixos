{ ... }: {
  imports = [ ./tailscale.nix ];

  # Router role: host may advertise subnet/exit routes via host-specific config.
  # Keep this module minimal so it does not force behavior on every router host.
  my.tailscale = { };
}
