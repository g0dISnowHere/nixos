{ inputs, ... }:
let
  inherit (inputs)
    nixpkgs home-manager nix-flatpak plasma-manager nixpkgs-unstable sops-nix
    nixpkgs-broken nixpkgs-zellij;
  secretsPolicy = import (builtins.path {
    path = ./secrets-policy.nix;
    name = "secrets-policy.nix";
  });
  sort = builtins.sort builtins.lessThan;
  hostNames = sort (builtins.attrNames secretsPolicy.hosts);
  operatorAlias = secretsPolicy.operator.alias;
  renderAgeList = aliases:
    builtins.concatStringsSep "\n"
    (map (alias: "          - *${alias}") aliases);
  renderKeyLine = alias: recipient: "  - &${alias} ${recipient}";
  renderRule = pathRegex: aliases: ''
      - path_regex: ${pathRegex}
        key_groups:
          - age:
    ${renderAgeList aliases}
  '';
  renderScopedRules = scopeName: extensionPattern: scopes:
    let names = sort (builtins.attrNames scopes);
    in builtins.concatStringsSep "\n" (map (name:
      let hosts = sort scopes.${name}.hosts;
      in renderRule "^secrets/${scopeName}/${name}/.*\\.${extensionPattern}$"
      ([ operatorAlias ] ++ hosts)) names);
  renderSopsConfig = policy:
    let
      policyHostNames = sort (builtins.attrNames policy.hosts);
      keys = [
        (renderKeyLine policy.operator.alias
          (builtins.head policy.operator.recipients))
      ] ++ map (host: renderKeyLine host policy.hosts.${host}.recipient)
        policyHostNames;
      userRules = renderScopedRules "users" "yaml" policy.scopes.users;
      serviceRules = renderScopedRules "services" "(yaml|json|env|ini)"
        policy.scopes.services;
      machineRules = builtins.concatStringsSep "\n" (map (host:
        renderRule "^secrets/machines/${host}/.*\\.(yaml|json|env|ini)$" [
          policy.operator.alias
          host
        ]) policyHostNames);
    in builtins.concatStringsSep "\n" [
      "keys:"
      (builtins.concatStringsSep "\n" keys)
      "creation_rules:"
      userRules
      serviceRules
      machineRules
      ""
    ];
in {
  flake.lib = {
    inherit secretsPolicy renderSopsConfig;
    renderedSopsConfig = renderSopsConfig secretsPolicy;
    # Helper function to create a NixOS system configuration.
    # New machine definitions should prefer explicit capability modules; role is
    # kept optional for transitional shared defaults.
    mkNixosSystem = { system, hostname, role ? null, desktopEnvironment ? null
      , enableHomeManager ? false, modules ? [ ], extraSpecialArgs ? { } }:
      let
        roleModules =
          if role != null then [ ../modules/nixos/roles/${role}.nix ] else [ ];
        desktopEnvironmentModule = if desktopEnvironment != null then
          ../modules/nixos/desktop/${desktopEnvironment}.nix
        else
          { };
        homeManagerModule = if enableHomeManager then [
          # Home Manager integration
          home-manager.nixosModules.home-manager
          ({ pkgs, ... }: {
            home-manager.backupCommand =
              pkgs.writeShellScript "home-manager-backup" ''
                set -eu

                target_path="$1"
                backup_root="$HOME/.local/state/home-manager-backups"
                timestamp="$(date +%Y%m%d-%H%M%S-%N)"

                case "$target_path" in
                  "$HOME"/*)
                    relative_path="''${target_path#$HOME/}"
                    ;;
                  *)
                    relative_path="external/$(basename "$target_path")"
                    ;;
                esac

                backup_dir="$backup_root/$(dirname "$relative_path")"
                backup_name="$(basename "$target_path").$timestamp"
                backup_path="$backup_dir/$backup_name"

                mkdir -p "$backup_dir"
                mv "$target_path" "$backup_path"

                find "$backup_root" -type f -mtime +30 -delete
                find "$backup_root" -depth -type d -empty -delete
              '';
          })
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [ sops-nix.homeManagerModules.sops ];
              extraSpecialArgs = {
                inherit desktopEnvironment dotfilesRoot inputs repoRoot;
                isNixosIntegrated = true;
                pkgs-unstable = import nixpkgs-unstable {
                  inherit system;
                  config.allowUnfree = true;
                };
              };
            };
          }
        ] else
          [ ];
        # Use the live checkout path so Home Manager out-of-store symlinks point
        # into the working tree instead of the immutable flake snapshot.
        repoRoot = "/home/djoolz/Documents/01_config/mine";
        dotfilesRoot = "${repoRoot}/dotfiles";
      in nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Machine-specific hardware and config
          ../nixos/machines/${hostname} # This is where the default.nix for centauri is imported

          # Desktop environment (if specified)
          desktopEnvironmentModule

          # Flatpak support
          nix-flatpak.nixosModules.nix-flatpak
          sops-nix.nixosModules.sops

          # Global Nix daemon settings
          ../modules/nixos/system/nix-settings.nix
          ../modules/nixos/system/secrets.nix
          ../modules/nixos/users/djoolz/default.nix
          ../modules/nixos/users/djoolz/ssh.nix
          { nixpkgs.config.allowUnfree = true; }
        ] ++ roleModules ++ homeManagerModule ++ modules;

        specialArgs = {
          inherit inputs hostname desktopEnvironment repoRoot dotfilesRoot;
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-tailscale = import nixpkgs-broken {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-zellij = import nixpkgs-zellij {
            inherit system;
            config.allowUnfree = true;
          };
        } // extraSpecialArgs;
      };
  };
}
