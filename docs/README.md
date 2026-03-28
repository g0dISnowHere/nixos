# Documentation

`docs/` explains the architecture and design of the repo at a stable level. The
goal is to document how the major areas fit together and what each area is for,
without forcing the docs to change every time an implementation detail moves.

## Documentation Layers

- `README.md`
  - quick project overview for someone landing in the repo
- `docs/`
  - stable design and structure notes
- `docs/findings/`
  - detailed investigations, recaps, and point-in-time analysis
- `docs/future-ideas/`
  - proposals, plans, and work that is not yet canonical

## Sections

- `architecture/`
  - repo-level design boundaries and patterns
- `operations/`
  - the operational side of the system and how workflows are framed
- `vps/`
  - the VPS-specific architectural slice and migration area
- `dotfiles/`
  - the role of raw config files in the overall design

## Documentation Philosophy

- explain ownership, intent, and boundaries
- prefer stable concepts over volatile implementation detail
- let `findings/` and `future-ideas/` carry the more detailed and time-sensitive
  material
