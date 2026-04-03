{ inputs, ... }: {
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake.homeConfigurations = let
    # Standalone Home Manager profiles need the live checkout path so
    # mkOutOfStoreSymlink targets the working tree instead of the flake snapshot.
    repoRoot = "/home/djoolz/Documents/01_config/mine";
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
        pkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      modules = [
        ./users/djoolz/workstation.nix
        {
          home.username = "djoolz";
          home.homeDirectory = "/home/djoolz";
          # Do not change casually. See docs/architecture/state-version-reasons.md.
          home.stateVersion = "25.11";
        }
      ];
    };
  };
}
