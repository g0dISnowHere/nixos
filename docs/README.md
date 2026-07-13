# Documentation

`docs/` = human doc cave. Split by job so stable truth, quick lookup, rough
ideas not mix.

## Entry Points

- `README.md`: repo front door
- `docs/README.md`: doc map
- `AGENTS.md`: AI worker law

## Knowledge Base Flow

Repo knowledge live here.

Before non-trivial change:

- read `docs/README.md`
- open linked pages for task

When new thing worth keeping:

- update right page under `docs/`
- keep short, factual
- prefer commands, gotchas, decisions
- no duplicate fact spread everywhere

## Doc Types

- canonical docs: stable structure, architecture, operator flow
- agent config docs: repo-specific configuration consumed by engineering skills and other automation
- reference docs: quick commands, checklists, snippets
- incubator docs: findings, proposals, future work, not canon yet
- local-area docs: subtree-local notes near code

## Sections

- `agents/`: repo-specific configuration consumed by engineering skills (`issue-tracker.md`, `triage-labels.md`, `domain.md`)
- `secrets-workflows.md`: SOPS operator guide
- `architecture/`: design boundaries, structure decisions
- `reference/`: quick lookup material (`ai-skills.md` covers installed skill packs, OMP repo scoping, and submodule refresh; `flake-linter.md` includes lint commands and response steps; `nix-fast-build.md` covers fast multi-target builds)
- `dev-templates.md`: local flake template workflow
- `vps/`: VPS context, runbooks
- `dotfiles/`: why `dotfiles/` exist, how fit repo
- `findings/`: dated investigations
- `future-ideas/`: drafts, proposals, backlog

## Placement Rules

- stable repo docs go in `docs/`
- agent-skill configuration lives in `docs/agents/`
- SOPS workflow truth goes in `docs/secrets-workflows.md`
- dev template workflow truth goes in `docs/dev-templates.md`
- command lists, checklists go in `docs/reference/`
- recurring issues, point-in-time analysis go in `docs/findings/`
- durable architecture decisions go in `docs/architecture/`
- incomplete plans, backlog ideas go in `docs/future-ideas/`
- subtree-specific docs stay near owner when not useful repo-wide

## Philosophy

- explain ownership, intent, boundaries
- prefer stable concepts over volatile detail
- promote incubator docs only when design current, intentional
