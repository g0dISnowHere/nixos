# Documentation

`docs/` is the human documentation system for this repo. It is organized by
document role so stable explanations, quick lookup material, and incubator
notes do not blur together.

## Entry Points

- `README.md`
  - repo landing page and first-stop overview
- `docs/README.md`
  - documentation taxonomy and navigation
- `AGENTS.md`
  - canonical AI guidance for coding agents

## Knowledge Base Workflow

The repo knowledge base lives in the existing `docs/` tree.

Before non-trivial changes:

- read `docs/README.md`
- open any linked pages relevant to the task

When you learn something worth keeping:

- update the relevant existing page under `docs/`
- keep entries concise and factual
- prefer concrete commands, gotchas, and decisions
- avoid duplicating information across pages

## Document Types

- canonical docs
  - stable repo structure, architecture, and operator workflows
- reference docs
  - short lookup material such as commands and checklists
- incubator docs
  - findings, proposals, and future work that are not canonical yet
- local-area docs
  - docs that belong to one subtree and stay near that code

## Sections

- `secrets-workflows.md`
  - canonical operator guide for the SOPS lifecycle
- `architecture/`
  - canonical design boundaries and structure decisions
  - includes capability-module composition and Home Manager/dotfiles boundaries
- `reference/`
  - quick lookup material for common commands and operational snippets
- `dev-templates.md`
  - canonical workflow for local flake project templates
- `vps/`
  - canonical VPS-specific context and runbooks
- `dotfiles/`
  - canonical explanation of the role of `dotfiles/` in the repo design
- `findings/`
  - incubator investigations and dated analysis
- `future-ideas/`
  - incubator proposals, drafts, and backlog material

## Placement Rules

- Put stable repo documentation in `docs/`.
- Put the canonical SOPS operator workflow in `docs/secrets-workflows.md`.
- Put the canonical development template workflow in `docs/dev-templates.md`.
- Put quick command lists and checklists in `docs/reference/`.
- Put recurring issues and point-in-time investigations in `docs/findings/`.
- Put durable architecture decisions and boundaries in `docs/architecture/`.
- Put incomplete plans and backlog ideas in `docs/future-ideas/`.
- Keep subtree-specific docs near their owning area when they are not useful as
  repo-wide canonical docs.

## Documentation Philosophy

- explain ownership, intent, and boundaries
- prefer stable concepts over volatile implementation detail
- promote incubator material into canonical docs only after the design is
  current and intentional
