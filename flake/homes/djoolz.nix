{ inputs, ... }: {
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake.homeConfigurations = let
    # Standalone home-manager profiles need the live checkout path so
    # mkOutOfStoreSymlink targets the working tree instead of the flake snapshot.
    repoRoot = "/home/djoolz/Documents/01_config/mine";
    dotfilesRoot = "${repoRoot}/dotfiles";
  in {
    # Standalone home-manager config for djoolz@workstation
    # Usage: home-manager switch --flake .#djoolz@workstation
    "djoolz@workstation" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      extraSpecialArgs = {
        desktop = "niri";
        inherit dotfilesRoot inputs repoRoot;
        pkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      modules = [
        ./users/djoolz/desktop.nix
        {
          home.username = "djoolz";
          home.homeDirectory = "/home/djoolz";
          home.stateVersion = "25.11";
        }
      ];
    };

    # CLI-only profile for servers
    # Usage: home-manager switch --flake .#djoolz@server
    "djoolz@server" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      extraSpecialArgs = {
        desktop = null;
        inherit dotfilesRoot inputs repoRoot;
        pkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      modules = [
        ./users/djoolz/common.nix
        {
          home.username = "djoolz";
          home.homeDirectory = "/home/djoolz";
          home.stateVersion = "25.11";
        }
      ];
    };
  };
}
