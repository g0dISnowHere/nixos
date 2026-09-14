Yes—but there is **no single mature “agentic Nix developer” skill** that I would trust unattended. The available options are mostly documentation routers rather than complete development workflows.

## Useful existing options

### 1. `marceloeatworld/nixos-ai-skill` — best general Nix knowledge skill

This is currently the strongest starting point. It contains a `SKILL.md` that routes the agent into roughly 40 reference files generated from official `nix.dev`, `nixpkgs`, Nix Pills, and NixOS release documentation. The references are updated automatically and it supports Codex, Claude Code, Cursor, Gemini CLI, and other Agent Skills-compatible tools. ([GitHub][1])

**Good for:**

* Nix language and flakes
* NixOS modules
* Packaging and derivations
* NixOS tests
* Administration and troubleshooting

**Limitation:** it gives the agent knowledge, but does not enforce a safe repository workflow.

### 2. `majiayu000/claude-skill-registry/…/nix` — research-oriented

This skill maps Nix questions to relevant repositories such as `NixOS/nix.dev`, `NixOS/nixpkgs`, Home Manager, `nix-init`, `nix-update`, and `nixpkgs-review`. It instructs Claude to query them through DeepWiki using parallel subagents. ([GitHub][2])

It covers more ecosystem projects than the first option, but it is tightly coupled to:

* Claude-style subagents
* DeepWiki MCP
* Network access
* A particular research workflow

That makes it less attractive for your local-LLM setup and less portable to Codex.

### 3. Smaller specialized skills

There are smaller skills covering things such as:

* `nix run`, `nix shell`, and `nix develop`
* Hash generation using `nurl`
* Home Manager overlay placement
* Basic NixOS configuration patterns

These may be useful as snippets, but most are too narrow to serve as a serious Nix repository maintainer.

## Declarative skill management

`agent-skills-nix` is probably more relevant to your setup than any individual skill. It lets you pin external skill repositories, discover `SKILL.md` files, select specific skills, bundle dependencies, and install them into Codex, Claude Code, Pi, Gemini, Cursor, and other agents. ([GitHub][3])

It supports:

* Flake-pinned or `npins`-locked sources
* Global and project-local skills
* Separate Codex and Claude targets
* Bundled CLI dependencies
* `copy-tree`, `symlink-tree`, or normal Home Manager links
* Checks for duplicate skill IDs and invalid paths ([GitHub][3])

Home Manager also has native `programs.claude-code.skills` support, including inline skills, individual `SKILL.md` files, and complete skill directories. ([Nix community projects][4])

For Codex, prefer `copy-tree` rather than exposing only Nix-store symlinks. Codex has had problems discovering symlinked `SKILL.md` files, while `agent-skills-nix` can dereference them during installation. ([GitHub][5])

## What I would use for your NixOS repository

Use a **two-layer setup**:

1. **General knowledge:** `nixos-ai-skill`
2. **Project workflow:** your own small `nix-repo-maintainer` skill

The custom skill should encode rules that generic Nix documentation cannot know:

```text
Before modifying anything:
- Read flake.nix, flake.lock, the target host definition, and imported modules.
- Determine whether the change belongs in system, host, hardware, service,
  package, or user configuration.
- Follow existing repository structure instead of introducing a new pattern.

Change rules:
- Do not update flake.lock unless explicitly requested.
- Preserve input follows relationships.
- Do not modify secrets or encrypted files.
- Avoid unrelated formatting and refactoring.
- Prefer small, reversible changes.
- Do not run nixos-rebuild switch without explicit permission.

Validation:
- Format changed Nix files.
- Run statix and deadnix when available.
- Run nix flake check.
- Evaluate the affected configuration.
- Build only the affected host:
  nixos-rebuild build --flake .#<host>
- Report warnings, build result, and rollback implications.
```

That would be substantially more useful than installing five generic Nix skills. The existing documentation-backed skill supplies syntax and ecosystem knowledge; your local skill supplies architecture, permissions, testing requirements, and safety boundaries.

[1]: https://github.com/marceloeatworld/nixos-ai-skill "GitHub - marceloeatworld/nixos-ai-skill: Auto-updated NixOS & Nix ecosystem documentation for AI coding assistants — works with 33+ tools via the Agent Skills standard (SKILL.md) · GitHub"
[2]: https://github.com/majiayu000/claude-skill-registry/blob/main/skills/development/nix/SKILL.md "claude-skill-registry/skills/development/nix/SKILL.md at main · majiayu000/claude-skill-registry · GitHub"
[3]: https://github.com/Kyure-A/agent-skills-nix "GitHub - Kyure-A/agent-skills-nix: Declarative management of Agent Skills on Nix · GitHub"
[4]: https://nix-community.github.io/home-manager/options/home-manager/programs/claude-code.html?utm_source=chatgpt.com "claude-code - Home Manager Manual"
[5]: https://github.com/openai/codex/issues/10470?utm_source=chatgpt.com "Cannot read a symlinked SKILL.md file · Issue #10470 · openai/codex"
