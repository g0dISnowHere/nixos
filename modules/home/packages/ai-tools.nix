{
  lib,
  pkgs,
  pkgs-unstable,
  repoRoot,
  desktopEnvironment ? null,
  ...
}:
{
  home.packages =
    with pkgs;
    [
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
      pkgs-unstable.fabric-ai # Fabric prompt/automation toolkit
      # codex-latest
    ]
    ++ pkgs.lib.optionals (desktopEnvironment != null) [
      pkgs-unstable.antigravity # Antigravity desktop AI client
    ];

  # Symlink skills from repo submodules into the AI assistant skill roots.
  # Silently skips any submodule that has not been initialised yet.
  home.activation.linkAiSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _skills_src="${repoRoot}/third-party/skills"
    for _target in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
      mkdir -p "$_target"

      # mattpocock-skills: category/name/SKILL.md at depth 3, skip deprecated
      if [ -d "$_skills_src/mattpocock-skills/skills" ]; then
        find "$_skills_src/mattpocock-skills/skills" \
          -mindepth 3 -maxdepth 3 -name SKILL.md -not -path '*/deprecated/*' \
          | sort | while IFS= read -r _md; do
              _dir="$(dirname "$_md")"
              ln -sfn "$_dir" "$_target/$(basename "$_dir")"
            done
      fi

      # stop-slop: whole directory
      if [ -d "$_skills_src/stop-slop" ]; then
        ln -sfn "$_skills_src/stop-slop" "$_target/stop-slop"
      fi

      # caveman: name/SKILL.md at depth 2 of plugins/caveman/skills
      if [ -d "$_skills_src/caveman/plugins/caveman/skills" ]; then
        find "$_skills_src/caveman/plugins/caveman/skills" \
          -mindepth 2 -maxdepth 2 -name SKILL.md \
          | sort | while IFS= read -r _md; do
              _dir="$(dirname "$_md")"
              ln -sfn "$_dir" "$_target/$(basename "$_dir")"
            done
      fi
    done
  '';
}
