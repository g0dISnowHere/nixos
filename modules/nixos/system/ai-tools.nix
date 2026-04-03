{ pkgs, pkgs-unstable, ... }: {
  # System-level AI CLI tools that should remain available on hosts without
  # Home Manager. Keep this limited to headless-safe command-line tooling.
  environment.systemPackages = [
    pkgs.gemini-cli
    pkgs.ripgrep
    pkgs.bubblewrap
    pkgs-unstable.opencode
    pkgs-unstable.fabric-ai
    pkgs-unstable.codex
  ];
}
