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
- reference docs: quick commands, checklists, snippets
- incubator docs: findings, proposals, future work, not canon yet
- local-area docs: subtree-local notes near code

## Sections

- `secrets-workflows.md`: SOPS operator guide
- `architecture/`: design boundaries, structure decisions
- `reference/`: quick lookup material
- `dev-templates.md`: local flake template workflow
- `vps/`: VPS context, runbooks
- `dotfiles/`: why `dotfiles/` exist, how fit repo
- `findings/`: dated investigations
- `future-ideas/`: drafts, proposals, backlog

## Placement Rules

- stable repo docs go in `docs/`
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
