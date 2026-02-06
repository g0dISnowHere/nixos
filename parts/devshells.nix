{ inputs, ... }:
{
  perSystem = { pkgs, system, ... }: {
    # Development environment for this flake
    # Available via: nix develop
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        nixpkgs-fmt # Nix code formatter
        statix # Nix linter for best practices
        deadnix # Dead code detection
      ];

      shellHook = ''
        echo "NixOS configuration development environment"
        echo "Current system: ${system}"
      '';
    };
  };
}
