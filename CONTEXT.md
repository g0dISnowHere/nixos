# Host Setup Composition

This repo models reproducible host setups built from explicit machine capabilities, user environments, and linked dotfiles. It exists to keep system behavior, user behavior, and raw application config separate but composable.

## Language

**Host Setup**:
A reproducible machine configuration assembled by the flake for a concrete host.
_Avoid_: machine config, system build, setup

**Capability Module**:
An explicit unit of machine behavior imported because a host needs that behavior.
_Avoid_: role module, machine role

**User Environment**:
The user-scoped layer that manages packages, session wiring, user services, settings, and dotfile links.
_Avoid_: system behavior, machine behavior

**Linked Dotfiles**:
Application-facing configuration kept in native file formats and linked into the user environment.
_Avoid_: Home Manager config, generated config

**Inventory Grouping**:
A human-oriented collection of concrete host setups used to organize the machine inventory. It should not be the source of a host's implicit behavior.
_Avoid_: role, behavior layer

**Canonical Host Definition**:
The single source of truth for a concrete host setup, including its capability selection and host-specific exceptions. In this repo, the intended home is `nixos/machines/<host>/default.nix`.
_Avoid_: split host definition, inventory-owned behavior

## Guardrail

Model this repo as one context with layered concepts while `Host Setup` remains the unifying object. Revisit a multi-context map only if operator or deployment workflows develop independent vocabulary and decisions that no longer reduce cleanly to host setup composition.
