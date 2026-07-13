# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root, if it exists
- **`docs/adr/`** at the repo root, reading ADRs relevant to the area being changed

If these files don't exist, proceed silently. Don't suggest creating them upfront; create them only when the domain-modeling workflow actually resolves terms or decisions.

## File structure

Single-context repo:

```text
/
├── CONTEXT.md
├── docs/adr/
└── src/
```

## Use the glossary's vocabulary

When naming domain concepts, use the terms defined in `CONTEXT.md`. Avoid inventing synonyms when the glossary already defines the term.

## Flag ADR conflicts

If a change contradicts an existing ADR, surface that explicitly instead of silently overriding it.
