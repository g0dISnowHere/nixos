# AI Skills

`pkgs-unstable.skills` provides the `skills` CLI. It owns global skill
discovery, installation, updates, and agent-directory links.

## Managed global skill packs

`scripts/global-skills.txt` is the canonical global skill-pack manifest: one
`skills add` source per non-comment line. `scripts/sync-ai-skills.sh` reads it,
refetches each declared source, and reinstalls its skills for every compatible
global agent. That updates only the declared packs, not unrelated global skills.

Inspect the manifest without changing state:

```bash
scripts/sync-ai-skills.sh --list
```

The synchronizer runs automatically after a successful
`scripts/update-system.sh` rebuild and during `scripts/gc.sh` before Nix
collection. Run it directly to repair or immediately refresh the global set:

```bash
scripts/sync-ai-skills.sh
```

The CLI records installed sources in `~/.agents/.skill-lock.json` and
materializes its universal skill root at `~/.agents/skills`. Codex and Pi are
explicitly supported adapters and both resolve these installed skills there.
OMP consumes the same directory; `skills` version 1.5.21 has no separate
`omp` adapter name.

Eve and PromptScript are listed by the CLI but do not support global skills;
`--all` reports and skips those two adapters.

### List or remove global skills

```bash
skills list -g --json
skills remove -g <skill-name> -y
```

## Per-repository skills

Run `skills add` from a repository without `-g` to install only for that
repository. Use `-a '*'` for every supported agent, or name individual agent
adapters such as `codex` or `pi`.

```bash
cd /path/to/repository
skills add <owner/repository> -a '*' -s <skill-name> -y
```

Project-scoped skills supplement global skills. Commit the relevant
agent-specific skill directory when the whole team should share it; otherwise
ignore it locally.

## Per-repo on/off (OMP only)

OMP reads `.omp/config.yml` in the project root. Use this to filter globally
available skills for an OMP session without copying them into the repository.

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
