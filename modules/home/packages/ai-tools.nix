{
  pkgs,
  pkgs-unstable,
  ...
}:
{
  home.packages = with pkgs; [
    # aider-chat-full # terminal pair-programming assistant
    # gemini-cli # installed via pnpm manifest
    # crush # local AI TUI assistant
    ripgrep # shared dependency used by multiple AI CLI workflows
    bubblewrap # sandbox helper used by some AI tooling
    rtk

    # claude-code # using npm package instead
    # claude-monitor
    # zed-editor
    # codex # installed via pnpm manifest

    pkgs-unstable.opencode # OpenCode CLI
    pkgs-unstable.antigravity-ide
    pkgs-unstable.fabric-ai # Fabric prompt/automation toolkit
    pkgs-unstable.skills # Agent skills CLI (vercel-labs/skills)
    # codex-latest
  ];

}
