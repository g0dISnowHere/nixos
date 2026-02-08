{ inputs, ... }: {
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake.homeConfigurations = {
    # Standalone home-manager config for djoolz@workstation
    # Usage: home-manager switch --flake .#djoolz@workstation
    "djoolz@workstation" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      extraSpecialArgs = {
        desktop = "gnome";
        inherit inputs;
        pkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      modules = [
        ./profiles/desktop.nix
        {
          home.username = "djoolz";
          home.homeDirectory = "/home/djoolz";
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
        inherit inputs;
        pkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      modules = [
        ./profiles/common.nix
        {
          home.username = "djoolz";
          home.homeDirectory = "/home/djoolz";
        }
      ];
    };
  };
}
