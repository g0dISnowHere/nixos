{ pkgs, ... }: {
  # System-level login shell wiring. Keep this narrow: it only ensures zsh is
  # installed and valid as the default shell for local users.
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;
}
