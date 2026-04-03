{ ... }: {
  # Thin wrapper that combines the reusable GUI baseline with
  # djoolz-specific personal settings for workstation-style homes.
  imports = [ ../../profiles/gui.nix ./personal.nix ];
}
