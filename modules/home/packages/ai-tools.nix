{ lib, pkgs, pkgs-unstable, desktopEnvironment ? null, ... }:

let
  headroomRuntimeLibraryPath = pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc
    pkgs.zlib
  ];

  headroomShim = pkgs.writeShellScript "headroom" ''
    set -euo pipefail

    headroom_bin="$HOME/.local/share/uv/tools/headroom-ai/bin/headroom"
    if [ ! -x "$headroom_bin" ]; then
      echo "headroom is not installed at $headroom_bin" >&2
      echo "Install it with your uv tool workflow first." >&2
      exit 1
    fi

    export NIX_LD="/run/current-system/sw/share/nix-ld/lib/ld.so"
    export NIX_LD_LIBRARY_PATH="/run/current-system/sw/share/nix-ld/lib"
    export LD_LIBRARY_PATH="${headroomRuntimeLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

    exec "$headroom_bin" "$@"
  '';
in

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
      rtk

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

  home.activation.installHeadroomShim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/bin"
    ln -sf "${headroomShim}" "$HOME/.local/bin/headroom"
  '';
}
