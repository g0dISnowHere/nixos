{ inputs, ... }: {
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake.homeConfigurations =
    let
      repoRootEnv = builtins.getEnv "REPO_ROOT";
      # Prefer an explicit live checkout path when provided. Fall back to the
      # flake source path so evaluation still works in pure contexts.
      repoRoot = if repoRootEnv != "" then repoRootEnv else builtins.toString ../..;
      dotfilesRoot = "${repoRoot}/dotfiles";
    in
    {
      # Standalone Home Manager config for GUI user environment.
      # Usage: home-manager switch --flake .#djoolz@gnome
      "djoolz@gnome" = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };

        extraSpecialArgs = {
          inherit dotfilesRoot inputs repoRoot;
          isNixosIntegrated = false;
          pkgs-unstable = import inputs.nixpkgs-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };

        modules = [
          ./users/djoolz/base.nix
          ./users/djoolz/gui-apps.nix
          ../../modules/home/packages/system-utils.nix
          ../../modules/home/packages/nix-tools.nix
          ../../modules/home/programs/shell.nix
          ../../modules/home/programs/developer-tools.nix
          ../../modules/home/packages/ai-tools.nix
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
