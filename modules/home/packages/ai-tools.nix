{ pkgs, pkgs-unstable, ... }:

{
  # AI assistant tooling lives here so installs and tool-specific notes stay together.
  home.packages = with pkgs;
    let
      # Optional pinned Codex build kept here with the rest of the AI tooling.
      # Enable `codex-latest` below if the unstable package lags behind a needed release.
      codex-latest = pkgs-unstable.codex.overrideAttrs (_old: {
        version = "0.104.0";
        src = pkgs-unstable.fetchFromGitHub {
          owner = "openai";
          repo = "codex";
          rev = "rust-v0.104.0";
          hash = "sha256-spWb/msjl9am7E4UkZfEoH0diFbvAfydJKJQM1N1aoI=";
        };
      });
    in [
      #################################################################################
      ## AI
      #################################################################################
      aider-chat-full # terminal pair-programming assistant
      gemini-cli # Google Gemini CLI
      crush # local AI TUI assistant
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
      pkgs-unstable.antigravity # Antigravity desktop AI client

      # codex-latest
      pkgs-unstable.codex
      # pkgs-unstable.aider-chat-full
    ];
}
