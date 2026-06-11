{ pkgs, ... }:
let
  version = "3.13";
  concatMajorMinor = v:
    pkgs.lib.pipe v [
      pkgs.lib.versions.splitVersion
      (pkgs.lib.sublist 0 2)
      pkgs.lib.concatStrings
    ];
  python = pkgs."python${concatMajorMinor version}";
in {
  env = {
    UV_CACHE_DIR = "$HOME/.cache/uv";
    UV_PYTHON_DOWNLOADS = "never";
    UV_PYTHON_PREFERENCE = "only-system";
  };

  packages = [
    python
    pkgs.basedpyright
    pkgs.git
    pkgs.just
    pkgs.mypy
    pkgs.pre-commit
    pkgs.ruff
    pkgs.uv
    python.pkgs.coverage
    python.pkgs.pytest
    python.pkgs.pytest-cov
  ];

  enterShell = ''
    mkdir -p "$UV_CACHE_DIR"
    activateVenv=1

    if [[ -x ".venv/bin/python" ]]; then
      venvVersion="$(.venv/bin/python -c 'import platform; print(platform.python_version())')"

      if [[ "$venvVersion" != "${python.version}" ]]; then
        printf '%s\n' \
          "Warning: Python version mismatch: [$venvVersion (venv)] != [${python.version}]" \
          "         Delete '.venv' and reload to rebuild for version ${python.version}"
        activateVenv=0
      fi
    else
      uv venv --python "${python}/bin/python" .venv
    fi

    if [[ "$activateVenv" -eq 1 && -f pyproject.toml && -f uv.lock ]]; then
      if ! uv sync --frozen --quiet; then
        echo "Warning: uv sync --frozen failed; continuing with the existing environment."
      fi
    fi

    if [[ "$activateVenv" -eq 1 && -f ".venv/bin/activate" ]]; then
      source ".venv/bin/activate"
    fi

    if [[ ! -d .git && -f pyproject.toml && -f .pre-commit-config.yaml ]]; then
      echo "Bootstrapping Git repository..."

      if git init -b main >/dev/null 2>&1; then
        :
      else
        git init >/dev/null
        git branch -M main >/dev/null 2>&1 || true
      fi

      if ! pre-commit install; then
        echo "Warning: pre-commit install failed; continuing without an installed hook."
      fi

      git add .

      if ! git diff --cached --quiet; then
        if git config --get user.name >/dev/null 2>&1 && git config --get user.email >/dev/null 2>&1; then
          if ! git commit -m "Initial commit"; then
            echo "Warning: initial commit failed; repository was initialized but no commit was created."
          fi
        else
          echo "Warning: git user.name/user.email not configured; skipping initial commit."
        fi
      fi
    fi
  '';
}
