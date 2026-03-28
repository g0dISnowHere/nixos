{ ... }: {
  # Support VS Code remote sessions that expect dynamic linker access.
  programs.nix-ld.enable = true;
}
