{ ... }: {
  # Thin wrapper that combines the reusable CLI baseline with
  # djoolz-specific personal settings for headless server homes.
  imports = [
    ../../profiles/base.nix
    ./personal.nix
  ];
}
