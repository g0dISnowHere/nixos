_: {
  perSystem =
    { pkgs, inputs', ... }:
    let
      flakeLinterPkg =
        if builtins.hasAttr "flake-linter" pkgs then
          pkgs."flake-linter"
        else
          inputs'.flake-linter.packages.default;
      markdownlintConfig = pkgs.writeText "markdownlint.jsonc" ''
        {
          "default": true,
          "MD022": false,
          "MD026": false,
          "MD029": false,
          "MD030": false,
          "MD031": false,
          "MD032": false,
          "MD013": false,
          "MD033": false,
          "MD034": false,
          "MD040": false,
          "MD041": false,
          "MD047": false,
          "MD053": false
        }
      '';

      markdownlint = pkgs.writeShellApplication {
        name = "markdownlint-repo";
        runtimeInputs = [
          pkgs.git
          pkgs.markdownlint-cli
        ];
        text = ''
          repo_root="$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)"
          cd "$repo_root"

          markdownlint_args=()

          if [[ "$#" -gt 0 && "$1" == "--fix" ]]; then
            markdownlint_args+=(--fix)
            shift
          fi

          if [[ "$#" -gt 0 ]]; then
            exec markdownlint --config "${markdownlintConfig}" "''${markdownlint_args[@]}" "$@"
          fi

          markdown_files=()
          while IFS= read -r -d "" path; do
            case "$path" in
              .claude/*|.gemini/*|.github/copilot-instructions.md|CLAUDE.md|GEMINI.md|dotfiles/basic\ niri.md|nixos/machines/centauri/trackpad.md)
                continue
                ;;
            esac

            if [[ ! -f "$path" ]]; then
              continue
            fi

            markdown_files+=("$path")
          done < <(git ls-files -z -- "*.md")

          if [[ "''${#markdown_files[@]}" -eq 0 ]]; then
            echo "No tracked markdown files to lint."
            exit 0
          fi

          exec markdownlint --config "${markdownlintConfig}" "''${markdownlint_args[@]}" "''${markdown_files[@]}"
        '';
      };

      shellcheck = pkgs.writeShellApplication {
        name = "shellcheck-repo";
        runtimeInputs = [
          pkgs.git
          pkgs.shellcheck
        ];
        text = ''
          repo_root="$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)"
          cd "$repo_root"

          shell_files=()
          while IFS= read -r -d "" path; do
            if [[ ! -f "$path" ]]; then
              continue
            fi

            shell_files+=("$path")
          done < <(
            git ls-files -z -- \
              '.githooks/pre-commit' \
              'scripts/*.sh' \
              'scripts/*/*.sh' \
              'scripts/*/*/*.sh' \
              'scripts/secrets'
          )

          if [[ "''${#shell_files[@]}" -eq 0 ]]; then
            echo "No tracked shell scripts to lint."
            exit 0
          fi

          exec shellcheck -x -e SC1091 -s bash "''${shell_files[@]}"
        '';
      };

      nixlint = pkgs.writeShellApplication {
        name = "nixlint-repo";
        runtimeInputs = [
          pkgs.git
          pkgs.statix
          pkgs.deadnix
        ];
        text = ''
          repo_root="$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)"
          cd "$repo_root"

          nix_files=()
          while IFS= read -r -d "" path; do
            case "$path" in
              modules/home/dconf/dconf.nix)
                continue
                ;;
            esac

            if [[ ! -f "$path" ]]; then
              continue
            fi

            nix_files+=("$path")
          done < <(git ls-files -z -- "*.nix")

          if [[ "''${#nix_files[@]}" -eq 0 ]]; then
            echo "No tracked Nix files to lint."
            exit 0
          fi

          for path in "''${nix_files[@]}"; do
            statix check "$path"
          done
          deadnix --fail "''${nix_files[@]}"
        '';
      };

      flakelint = pkgs.writeShellApplication {
        name = "flakelint-repo";
        runtimeInputs = [
          pkgs.git
          flakeLinterPkg
        ];
        text = ''
          repo_root="$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)"
          cd "$repo_root"

          flake-linter .
        '';
      };
    in
    {
      packages = {
        markdownlintRepo = markdownlint;
        shellcheckRepo = shellcheck;
        nixlintRepo = nixlint;
        flakelintRepo = flakelint;
      };

      checks = {
        markdownlint =
          pkgs.runCommand "markdownlint-check"
            {
              nativeBuildInputs = [
                pkgs.findutils
                pkgs.markdownlint-cli
              ];
            }
            ''
              cd ${../.}

              markdown_files=()
              while IFS= read -r -d "" path; do
                case "$path" in
                  ./\.claude/*|./\.gemini/*|./\.github/copilot-instructions.md|./CLAUDE.md|./GEMINI.md|./dotfiles/basic\ niri.md|./nixos/machines/centauri/trackpad.md)
                    continue
                    ;;
                esac

                markdown_files+=("''${path#./}")
              done < <(find . -type f -name "*.md" -print0)

              if [[ "''${#markdown_files[@]}" -eq 0 ]]; then
                echo "No markdown files to lint."
                touch "$out"
                exit 0
              fi

              markdownlint --config "${markdownlintConfig}" "''${markdown_files[@]}"
              touch "$out"
            '';

        shellcheck =
          pkgs.runCommand "shellcheck-check"
            {
              nativeBuildInputs = [
                pkgs.findutils
                pkgs.shellcheck
              ];
            }
            ''
              cd ${../.}

              shell_files=()
              while IFS= read -r -d "" path; do
                shell_files+=("''${path#./}")
              done < <(
                find . \
                  \( -path "./scripts" -o -path "./scripts/*" \) \
                  \( -type f -name "*.sh" -o -path "./scripts/secrets" \) \
                  -print0
                find . -path "./.githooks/pre-commit" -print0
              )

              if [[ "''${#shell_files[@]}" -eq 0 ]]; then
                echo "No shell scripts to lint."
                touch "$out"
                exit 0
              fi

              shellcheck -x -e SC1091 -s bash "''${shell_files[@]}"
              touch "$out"
            '';

        statix =
          pkgs.runCommand "statix-check"
            {
              nativeBuildInputs = [
                pkgs.findutils
                pkgs.statix
              ];
            }
            ''
              cd ${../.}

              nix_files=()
              while IFS= read -r -d "" path; do
                case "$path" in
                  ./modules/home/dconf/dconf.nix)
                    continue
                    ;;
                esac

                nix_files+=("''${path#./}")
              done < <(find . -type f -name "*.nix" -print0)

              if [[ "''${#nix_files[@]}" -eq 0 ]]; then
                echo "No Nix files to lint."
                exit 0
              fi

              for path in "''${nix_files[@]}"; do
                statix check "$path"
              done
              touch "$out"
            '';

        deadnix =
          pkgs.runCommand "deadnix-check"
            {
              nativeBuildInputs = [
                pkgs.findutils
                pkgs.deadnix
              ];
            }
            ''
              cd ${../.}

              nix_files=()
              while IFS= read -r -d "" path; do
                case "$path" in
                  ./modules/home/dconf/dconf.nix)
                    continue
                    ;;
                esac

                nix_files+=("''${path#./}")
              done < <(find . -type f -name "*.nix" -print0)

              if [[ "''${#nix_files[@]}" -eq 0 ]]; then
                echo "No Nix files to lint."
                exit 0
              fi

              deadnix --fail "''${nix_files[@]}"
              touch "$out"
            '';

        flake-linter =
          pkgs.runCommand "flake-linter-check"
            {
              nativeBuildInputs = [ flakeLinterPkg ];
            }
            ''
              cd ${../.}
              flake-linter .
              touch "$out"
            '';
      };
    };
}
