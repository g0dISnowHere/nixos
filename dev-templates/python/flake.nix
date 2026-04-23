{
  description = "A Nix-flake-based Python development environment";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11"; # unstable Nixpkgs

  outputs = { self, ... }@inputs:

    let
      supportedSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f:
        inputs.nixpkgs.lib.genAttrs supportedSystems
        (system: f { pkgs = import inputs.nixpkgs { inherit system; }; });

      /* Change this value ({major}.{min}) to
         update the Python virtual-environment
         version. When you do this, make sure
         to delete the `.venv` directory to
         have the hook rebuild it for the new
         version, since it won't overwrite an
         existing one. After this, reload the
         development shell to rebuild it.
         You'll see a warning asking you to
         do this when version mismatches are
         present. For safety, removal should
         be a manual step, even if trivial.
      */
      version = "3.13";
    in {
      devShells = forEachSupportedSystem ({ pkgs }:
        let
          concatMajorMinor = v:
            pkgs.lib.pipe v [
              pkgs.lib.versions.splitVersion
              (pkgs.lib.sublist 0 2)
              pkgs.lib.concatStrings
            ];

          python = pkgs."python${concatMajorMinor version}";
        in {
          default = pkgs.mkShellNoCC {
            venvDir = ".venv";

            shellHook = ''
              export UV_CACHE_DIR="$HOME/.cache/uv"
              export UV_PYTHON_DOWNLOADS="never"
              export UV_PYTHON_PREFERENCE="only-system"
              mkdir -p "$UV_CACHE_DIR"

              activateVenv=1

              if [[ -x "$venvDir/bin/python" ]]; then
                venvVersion="$("$venvDir/bin/python" -c 'import platform; print(platform.python_version())')"

                if [[ "$venvVersion" != "${python.version}" ]]; then
                  printf '%s\n' \
                    "Warning: Python version mismatch: [$venvVersion (venv)] != [${python.version}]" \
                    "         Delete '$venvDir' and reload to rebuild for version ${python.version}"
                  activateVenv=0
                fi
              else
                uv venv --python "${python}/bin/python" "$venvDir"
              fi

              if [[ "$activateVenv" -eq 1 && -f pyproject.toml && -f uv.lock ]]; then
                if ! uv sync --frozen --quiet; then
                  echo "Warning: uv sync --frozen failed; continuing with the existing environment."
                fi
              fi

              if [[ "$activateVenv" -eq 1 && -f "$venvDir/bin/activate" ]]; then
                source "$venvDir/bin/activate"
              fi

              if [[ ! -d .git && -f flake.nix && -f pyproject.toml && -f .pre-commit-config.yaml ]]; then
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
          };
        });
    };
}
