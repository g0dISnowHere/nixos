{ ... }: {
  perSystem = { pkgs, system, ... }:
    let nixLdLibraryPath = pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ];
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [ python3 nixpkgs-fmt statix deadnix ];

        NIX_LD_LIBRARY_PATH = nixLdLibraryPath;
        NIX_LD =
          builtins.readFile "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
        GREET = "nixos config";
        ZDOTDIR = "/etc/zsh";
        # HISTFILE = toString ../. + "/.zsh_history";

        shellHook = ''
          export REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

          alias update="cd \"$REPO_ROOT\" && nix flake update"
          alias check="cd \"$REPO_ROOT\" && nix flake check"
          alias fmt="cd \"$REPO_ROOT\" && nix fmt"
          alias switch="cd \"$REPO_ROOT\" && sudo nixos-rebuild switch --flake .# 2>&1 | tee nixos-switch.log || { grep --color error nixos-switch.log && exit 1; }"
          alias test="cd \"$REPO_ROOT\" && sudo nixos-rebuild test --flake .# 2>&1 | tee nixos-switch.log || { grep --color error nixos-switch.log && exit 1; }"
          alias gc="sudo nix-collect-garbage --delete-older-than 10d && nix-collect-garbage --delete-older-than 10d && nix-store --optimise"

          echo "NixOS configuration development environment"
          echo "Current system: ${system}"
        '';
      };
    };
}
