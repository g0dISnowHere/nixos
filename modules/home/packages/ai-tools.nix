{ pkgs, pkgs-unstable, desktopEnvironment ? null, ... }:

{
  # AI assistant tooling lives here so installs and tool-specific notes stay together.
  home.packages = with pkgs;
    [
      #################################################################################
      ## AI
      #################################################################################
      # aider-chat-full # terminal pair-programming assistant
      gemini-cli # Google Gemini CLI
      # crush # local AI TUI assistant
      ripgrep # shared dependency used by multiple AI CLI workflows
      bubblewrap # sandbox helper used by some AI tooling

      # claude-code # using npm package instead
      # claude-monitor
      # zed-editor
      # codex
    ] ++ [
      #################################################################################
      ## AI (bleeding edge)
      #################################################################################
      pkgs-unstable.opencode # OpenCode CLI
      pkgs-unstable.fabric-ai # Fabric prompt/automation toolkit

      # GUI-only AI client; keep it off headless/server profiles.
      # codex-latest
    ] ++ pkgs.lib.optionals (desktopEnvironment != null) [
      pkgs-unstable.antigravity # Antigravity desktop AI client
    ] ++ [
      # codex-latest
      pkgs-unstable.codex
      # pkgs-unstable.aider-chat-full
    ];
}
