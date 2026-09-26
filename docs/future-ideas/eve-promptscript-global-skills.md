# Eve and PromptScript skill delivery

## Status

`scripts/sync-ai-skills.sh` installs managed packs globally with `skills add -g --all`. The Skills CLI installs the packs for supported adapters, then reports failures because Eve and PromptScript do not support global skill installation.

The sync script currently treats only these two known errors as non-fatal, so unrelated updates complete. Eve and PromptScript still do not receive the managed skills.

## Decision required

Choose one supported delivery path before claiming those agents have `ponytail` or any other managed global skill:

- Install the packs per repository if Eve and PromptScript support project-scoped skills.
- Use each agent's native project instruction mechanism.
- Stop targeting these agents until the Skills CLI adds global-skill support.

Do not add undocumented symlinks into agent directories. They bypass the adapters' supported discovery paths and may break on upgrades.

## Supersession

Delete this note after choosing and implementing a delivery path, or after the Skills CLI adds global support for both adapters.
