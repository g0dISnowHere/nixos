{ inputs, ... }: {
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake.homeConfigurations = let
    repoRootEnv = builtins.getEnv "REPO_ROOT";
    # Prefer an explicit live checkout path when provided. Fall back to the
    # flake source path so evaluation still works in pure contexts.
    repoRoot =
      if repoRootEnv != "" then repoRootEnv else builtins.toString ../..;
    dotfilesRoot = "${repoRoot}/dotfiles";
  in {
    # Standalone Home Manager config for djoolz@workstation
    # Usage: home-manager switch --flake .#djoolz@workstation
    "djoolz@workstation" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      extraSpecialArgs = {
        desktopEnvironment = "gnome";
        inherit dotfilesRoot inputs repoRoot;
        isNixosIntegrated = false;
        pkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      modules = [
        ./users/djoolz/workstation.nix
        {
          home = {
            username = "djoolz";
            homeDirectory = "/home/djoolz";
            # Do not change casually. See docs/architecture/state-version-reasons.md.
            stateVersion = "25.11";
          };
        }
      ];
    };
  };
}
