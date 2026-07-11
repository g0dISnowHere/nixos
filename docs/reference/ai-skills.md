# AI Skills

Skills are structured instruction documents that AI coding assistants (OMP, Claude Code) load
on demand to apply consistent patterns to common tasks. This repo installs three skill packs as
git submodules and symlinks them into the user-level skill roots.

## Installed skills

Skills are symlinked into `~/.agents/skills/` and `~/.claude/skills/` by `scripts/setup-ai-skills`.

### mattpocock-skills

Source: `third-party/skills/mattpocock-skills/skills/` (all subdirs except `deprecated/`)

| Category | Skills |
| --- | --- |
| engineering | ask-matt, code-review, codebase-design, diagnosing-bugs, domain-modeling, grill-with-docs, implement, improve-codebase-architecture, prototype, research, resolving-merge-conflicts, setup-matt-pocock-skills, tdd, to-spec, to-tickets, triage, wayfinder |
| productivity | grilling, grill-me, handoff, teach, writing-great-skills |
| in-progress | claude-handoff, loop-me, setup-ts-deep-modules, wizard, writing-beats, writing-fragments, writing-shape |
| misc | git-guardrails-claude-code, migrate-to-shoehorn, scaffold-exercises, setup-pre-commit |
| personal | edit-article, obsidian-vault |

### stop-slop

Source: `third-party/skills/stop-slop/` (symlinked whole; `SKILL.md` references `references/` assets via relative paths)

### caveman

Source: `third-party/skills/caveman/plugins/caveman/skills/` (4 skills, flat layout)

| Skill | What it does |
| --- | --- |
| caveman | Compress every reply to caveman-speak — same answer, ~65% fewer output tokens |
| caveman-compress | Rewrite a memory file (e.g. `CLAUDE.md`) into caveman-speak to cut input tokens each session |
| caveman-stats | Real session token usage, lifetime savings, USD |
| cavecrew | Caveman subagents (investigator, builder, reviewer) |

## Setup

The symlinks are created automatically when entering the devenv shell:

```bash
devenv shell
```

Or run manually at any time (idempotent):

```bash
bash scripts/setup-ai-skills
```

## Per-repo on/off (OMP only)

OMP reads `.omp/config.yml` in each project root. Claude Code does not support per-repo skill suppression.

### Suppress specific skills

```yaml
# <repo>/.omp/config.yml
skills:
  ignoredSkills:
    - stop-slop
    - tdd
    - writing-great-skills
```

Glob patterns are accepted: `- writing-*` suppresses all skills whose name starts with `writing-`.

### Allowlist (only these skills active in this repo)

```yaml
# <repo>/.omp/config.yml
skills:
  includeSkills:
    - tdd
    - implement
    - code-review
```

## Updating submodules

When upstream skill packs publish new content:

```bash
git submodule update --remote third-party/skills/mattpocock-skills third-party/skills/stop-slop third-party/skills/caveman
git add third-party/skills
git commit -m "chore: update ai skill submodules"
```

Then re-enter devenv shell (or run `bash scripts/setup-ai-skills`) to refresh the symlinks.
