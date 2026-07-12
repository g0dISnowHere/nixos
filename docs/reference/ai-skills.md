# AI Skills

Three skill packs installed as git submodules, symlinked into `~/.agents/skills/`
and `~/.claude/skills/` by Home Manager activation on every switch.

## Skill packs

| Pack | Source path | Link strategy |
| --- | --- | --- |
| mattpocock-skills | `third-party/skills/mattpocock-skills/skills/<category>/<name>/` | one symlink per skill, `deprecated/` excluded |
| stop-slop | `third-party/skills/stop-slop/` | whole directory |
| caveman | `third-party/skills/caveman/plugins/caveman/skills/<name>/` | one symlink per skill |

### caveman skills

| Skill | Purpose |
| --- | --- |
| caveman | Compress replies to caveman-speak (~65% fewer output tokens) |
| caveman-compress | Rewrite a memory file into caveman-speak to cut input tokens |
| caveman-stats | Real session token usage and lifetime savings |
| cavecrew | Caveman subagents (investigator, builder, reviewer) |

## Per-repo on/off (OMP only)

OMP reads `.omp/config.yml` in the project root.

```yaml
# suppress specific skills
skills:
  ignoredSkills:
    - stop-slop
    - tdd
```

```yaml
# allowlist — only these skills active here
skills:
  includeSkills:
    - tdd
    - code-review
```

Glob patterns accepted: `- writing-*`.

## Updating submodules

```bash
git submodule update --remote third-party/skills/mattpocock-skills third-party/skills/stop-slop third-party/skills/caveman
git add third-party/skills
git commit -m "chore: update ai skill submodules"
```

Re-run `nixos-rebuild switch` (or `home-manager switch`) to refresh symlinks.
