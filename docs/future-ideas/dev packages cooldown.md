Yes. For `uvx`, `npx`, `pnpm dlx`, etc., you need to configure the **runtime package manager**, not NixOS.

## Python / `uvx`

`uv` has exactly the relevant mechanism: `--exclude-newer`.

For one command:

```bash
uvx --exclude-newer "60 days" ruff
```

or:

```bash
uv tool run --exclude-newer "60 days" ruff
```

`uv` documents `--exclude-newer` as limiting candidate packages to artifacts uploaded before a given date, and it accepts friendly durations like `30 days`; it can also be set through `UV_EXCLUDE_NEWER`. It compares against the upload time of each distribution artifact, not the package version’s release date. ([docs.astral.sh][1])

For a persistent shell-level policy:

```bash
export UV_EXCLUDE_NEWER="60 days"
```

On NixOS/Home Manager:

```nix
home.sessionVariables = {
  UV_EXCLUDE_NEWER = "60 days";
};
```

or system-wide:

```nix
environment.sessionVariables = {
  UV_EXCLUDE_NEWER = "60 days";
};
```

Important limitation: `uv` docs say calendar units like months are not allowed for durations, so use `60 days` instead of `2 months`. ([docs.astral.sh][1])

## npm / `npx`

For current `npm`, the older broadly documented option is `--before`, which tells `npm install` to only use versions available on or before a timestamp. The npm docs describe `before` as rebuilding the dependency tree so only versions available on or before that time are installed. ([npm Docs][2])

For a one-off:

```bash
npx --before="$(date -u -d '60 days ago' +%Y-%m-%dT%H:%M:%SZ)" some-package
```

But this is less convenient than `uv`, because `npm`’s `before` wants an actual date, not a rolling “60 days” expression.

A wrapper is better:

```bash
#!/usr/bin/env bash
set -euo pipefail

cutoff="$(date -u -d '60 days ago' +%Y-%m-%dT%H:%M:%SZ)"
exec npx --before="$cutoff" "$@"
```

Save as e.g.:

```bash
~/.local/bin/npx-safe
```

Then:

```bash
npx-safe create-vite
npx-safe eslint
npx-safe prettier
```

## pnpm / `pnpm dlx`

`pnpm` has a cleaner native policy:

```yaml
minimumReleaseAge: 86400
```

`pnpm` defines `minimumReleaseAge` in **minutes**, and it applies to all dependencies, including transitive ones. `86400` minutes is 60 days. ([pnpm][3])

Global config:

```bash
pnpm config set minimumReleaseAge 86400 --global
pnpm config set minimumReleaseAgeStrict true --global
```

Then:

```bash
pnpm dlx some-package
```

will respect the age gate.

## Recommended NixOS setup

For development, I would make explicit wrapper commands instead of silently changing `npx`/`uvx`.

```nix
{ pkgs, ... }:

let
  npxSafe = pkgs.writeShellScriptBin "npx-safe" ''
    set -euo pipefail
    cutoff="$(${pkgs.coreutils}/bin/date -u -d '60 days ago' +%Y-%m-%dT%H:%M:%SZ)"
    exec ${pkgs.nodejs}/bin/npx --before="$cutoff" "$@"
  '';

  uvxSafe = pkgs.writeShellScriptBin "uvx-safe" ''
    set -euo pipefail
    exec ${pkgs.uv}/bin/uvx --exclude-newer "60 days" "$@"
  '';
in
{
  environment.systemPackages = with pkgs; [
    uv
    nodejs
    pnpm
    npxSafe
    uvxSafe
  ];

  environment.sessionVariables = {
    UV_EXCLUDE_NEWER = "60 days";
  };
}
```

Then use:

```bash
uvx-safe ruff
npx-safe create-vite
pnpm dlx some-tool
```

## My practical recommendation

Use:

```text
uvx-safe     for Python one-off tools
npx-safe     for npm one-off tools
pnpm config  for pnpm/dlx
```

Do **not** rely on NixOS alone for this. `uvx` and `npx` fetch from PyPI/npm at runtime, so the enforcement has to happen in `uv`, `npm`, `pnpm`, or a wrapper/proxy.

[1]: https://docs.astral.sh/uv/reference/cli/ "Commands | uv"
[2]: https://docs.npmjs.com/cli/v8/using-npm/config?utm_source=chatgpt.com "config"
[3]: https://pnpm.io/settings "Settings (pnpm-workspace.yaml) | pnpm"
