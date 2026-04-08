# Guided Secrets UX

## Goal

`scripts/secrets` should be the only command an operator needs to remember for
normal SOPS lifecycle work in this repo.

The UX should stay CLI-only.

The operator should not need to remember the internal command split between:

- `doctor`
- `add-host`
- `register-host`
- `retire-host`
- `user-scope`
- `create`
- `recover-access`
- `sync-policy`
- `validate-*`

Those are implementation details. The normal UX should be guided end to end.

## Problem

The current scripts are useful building blocks, but they still leak workflow
structure to the operator.

Current pain points:

- the user still has to remember multiple subcommands
- cross-machine onboarding is still conceptually split between target and
  operator machines
- `doctor --fix` often points to another command instead of finishing the task
- host rotation is hidden behind `register-host --force-host-rotate`
- user-scope management expects the operator to remember mutation flags
- policy sync and validation are still exposed as separate operator concepts
  during ordinary lifecycle changes

This is the wrong abstraction level for normal operations.

## UX Standard

The default operator entrypoint should be:

```bash
scripts/secrets
```

That command should:

- inspect current state safely by default
- detect whether it is running on a target host, an operator machine, or a
  recovery machine, and inspect the locally available operator and host age
  identities
- classify the current state into a bounded set of known conditions and suggest
  the matching workflow
- offer bounded choices for lifecycle tasks
- either complete the local workflow or emit the exact next step required on
  another machine
- finish mutating flows with validation

The operator should only need to answer the minimum unavoidable questions.

## Design Principles

### One Front Door

`scripts/secrets` is the public operator interface.

Subcommands may still exist, but they should be treated as:

- understandable CLI workflows behind the front door
- non-interactive interfaces for automation
- testable units behind the guided UX

The exact script names do not matter as much as clear operator meaning.

### Task-Oriented, Not Command-Oriented

The interface should ask:

- what are you trying to do?

Not:

- which subcommand do you want?

### Safe By Default

Normal entry should be read-only until the operator explicitly chooses a
mutating flow.

Every mutating flow should:

- show the planned changes
- confirm before destructive work
- validate after mutation

### Fail Closed

Secrets workflows must never “helpfully” overwrite key material or rewrite
recipient state when the actual state is unreadable, malformed, or ambiguous.

Examples:

- create missing keys when they are truly missing
- keep existing readable valid keys
- stop on unreadable or malformed keys unless the operator explicitly enters a
  rotation or repair flow
- do not rewrite recipients unless the workflow explicitly intends to rotate
  and decryptability has already been proven with a valid existing key

### Cross-Machine Clarity

Some workflows are single-machine. Some explicitly require both a target host
and an operator machine.

Host onboarding is separate from normal secret lifecycle work. It is the
workflow family that most often spans machines because the target host owns the
host `sops-nix` identity while the operator machine owns repo mutation and
rekeying.

When a workflow spans two machines, the CLI must say so explicitly.

The operator should never have to infer whether a step runs on:

- the target host
- the operator machine
- a recovery machine

That boundary should be shown every time.

The operator should also never have to infer what information to carry between
machines.

Preferred handoff model:

- if local state is sufficient, complete the workflow on the current machine
- if another machine is required, emit an explicit handoff artifact or exact
  next command
- the handoff must name the destination machine role, required inputs, and next
  validation step

Preferred default:

- start with exact next-command output because it is easiest to understand,
  copy, document, and debug
- add handoff files later only if the required payload becomes too large or too
  error-prone to pass as explicit command arguments

Examples of acceptable CLI-only handoff:

- print the exact command to run on the other machine with all required
  arguments
- write a small handoff file that a follow-up CLI command can consume on the
  next machine

## Primary Guided Flows

These should become first-class lifecycle tasks in the guided CLI.

In this document, "affected secrets" means the secret files whose recipients
must change because of the chosen workflow, based on explicit policy ownership
and membership.

### Inspect

Safe default mode.

Purpose:

- explain current state
- identify likely problems
- suggest or enter the appropriate workflow

### Onboard Host

End-to-end new host onboarding.

This is a distinct workflow family from ordinary secret creation, access
management, rotation, and retirement.

Expected shape:

1. prepare target host
   - bootstrap host `sops-nix` key if needed
   - capture the target host recipient
   - emit the handoff data needed by the operator machine
2. complete on operator machine
   - add host to policy
   - choose user/service membership
   - sync `.sops.yaml`
   - rekey affected secrets
   - validate policy and access

The operator should not need to remember `add-host --recipient ...`.

### Rotate Host Key

Replace the host recipient for an existing machine safely.

Expected shape:

- verify the operator can decrypt affected secrets first
- require explicit confirmation
- update policy
- sync `.sops.yaml`
- rekey affected secrets
- validate policy and host access

This should be a first-class flow, not a flag hidden on `register-host`.

### Retire Host

Remove a host from policy and revoke shared secret access.

Expected shape:

- block if machine-scoped secrets still exist
- point to the next required cleanup or migration step
- show all affected shared secrets
- remove host from policy
- sync `.sops.yaml`
- rekey
- validate policy and access

### Manage User Access

Manage `users.<name>` host membership through a guided interface.

Expected tasks:

- add host to user scope
- remove host from user scope
- replace exact membership
- retire empty user scope

The operator should not need to think in terms of `--host`, `--add-host`,
`--remove-host`, or `--retire`.

### Create Secret

Guided secret creation by scope.

Expected shape:

- choose target scope
- choose file name and format
- ensure operator key is valid
- edit plaintext
- encrypt
- validate policy placement if needed

This flow assumes host onboarding and scope ownership already exist.

### Recover Operator Access

Recover decryptability from a still-working machine.

Expected shape:

- identify source key candidates
- identify target operator recipient
- update policy
- sync `.sops.yaml`
- rekey affected secrets
- validate policy and target operator access

This should remain conservative, but the UX should still be guided.

## Additional Flows

The guided UX should also support:

- bootstrap operator machine
- rotate operator recipients
- rotate secret values
- move a secret between scopes
- audit current access for host, scope, or secret
- diagnose policy or `.sops.yaml` drift and point to the next action or apply
  the safe fix after confirmation

These are real lifecycle events and should not remain ad hoc.

## Structure Direction

Keep the root operator entrypoint:

- `scripts/secrets`

Keep reusable implementation below it:

- `scripts/secrets-lib/`
- `scripts/secrets-workflows/`

But change the ownership model:

- `scripts/secrets` owns operator UX and routing
- workflow scripts become implementation units
- library scripts provide inspection, mutation, and validation helpers

Keep the behavioral split explicit:

- host onboarding is separate from ordinary secrets lifecycle workflows
- inspection stays read-only by default
- blocked workflows must point to the next concrete step
- non-interactive equivalents remain available for automation

## Migration Plan

### Phase 1

Unify the UX model without deleting existing workflows.

- keep existing subcommands working
- keep understandable non-interactive CLI workflows for automation
- add a top-level guided CLI dispatcher in `scripts/secrets`
- make inspection and guided remediation share the same state model
- improve cross-machine handoff so the CLI prints or writes the exact next step

### Phase 2

Promote first-class lifecycle tasks:

- onboard host
- rotate host key
- retire host
- manage user access
- create secret
- recover operator access

### Phase 3

Add the missing secondary lifecycle tasks:

- bootstrap operator machine
- rotate operator recipients
- rotate secret values
- move secret scope
- audit access
- repair drift

### Phase 4

Demote raw subcommands in documentation.

Docs should describe:

- tasks and intent

Not:

- which raw internal command to memorize

## Success Criteria

This design is working when:

- an operator can start with only `scripts/secrets`
- the tool asks only minimal necessary questions
- cross-machine steps are explicit
- the tool completes the chosen task end to end when possible
- all mutation flows end with validation
- ordinary operations do not require remembering internal subcommands

## Non-Goal

This does not require removing all subcommands.

Advanced and internal entrypoints can remain useful for:

- testing
- recovery
- scripting
- debugging

They just should not be the primary operator UX.
