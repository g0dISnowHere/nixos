# GitHub Copilot Instructions (Repo-Scoped)

Use [`AGENTS.md`](../AGENTS.md) as the canonical repository guidance. This file
is only a short companion mirror.

## Core Rules
- Keep modules self-contained and use explicit imports only.
- Keep shared config in reusable modules and machine-specific config in `nixos/machines/`.
- Treat Home Manager as a portable user-environment layer, not a requirement to rewrite all dotfiles in Nix.
- Prefer linking files from `dotfiles/` before re-expressing them as Home Manager config when file-based config is already the better fit.

## Fast Validation
- Prefer `nix eval` and `nix flake check` during iteration.
- Use `nixos-rebuild` only when you are intentionally testing or applying a machine configuration.

## Documentation
- Human docs start at [`README.md`](../README.md) and [`docs/README.md`](../docs/README.md).
- `AGENTS.md` is the AI source of truth.
- Quick lookup docs live under `docs/reference/`.
- Incubator material belongs in `docs/findings/` or `docs/future-ideas/`.
- Subtree-local AI docs may exist for scoped implementation guidance only; when
  working under `scripts/`, also review [`scripts/README.md`](../scripts/README.md)
  and [`scripts/README_FOR_AI.md`](../scripts/README_FOR_AI.md).
