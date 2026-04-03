# Machine Configurations

`nixos/machines/` contains the host-local layer of the repo. Each subdirectory
represents a concrete machine and carries the pieces that are truly specific to
that host.

## Role

Machine directories are where shared composition meets reality:

- hardware-detected state
- host overrides
- install-time or disk-layout specifics when needed

## Design Intent

Keep these directories small. Shared behavior should come from reusable modules
and flake composition, while the machine folder should only express what the
shared layers cannot. Keep broader architecture explanation in `docs/`; this
README should stay about host-local ownership.
