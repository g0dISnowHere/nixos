{ inputs, ... }:
let
  inherit (inputs)
    nixpkgs
    nix-flatpak
    nixpkgs-unstable
    sops-nix
    ;
  mkPkgs =
    nixpkgsInput: system:
    import nixpkgsInput {
      inherit system;
      config.allowUnfree = true;
    };
  repoRootEnv = builtins.getEnv "REPO_ROOT";
  repoRootDefault = if repoRootEnv != "" then repoRootEnv else builtins.toString ../.;
  secretsPolicy = import (
    builtins.path {
      path = ./secrets-policy.nix;
      name = "secrets-policy.nix";
    }
  );
  sort = builtins.sort builtins.lessThan;
  operatorAlias = secretsPolicy.operator.alias;
  renderAgeList =
    aliases: builtins.concatStringsSep "\n" (map (alias: "          - *${alias}") aliases);
  renderKeyLine = alias: recipient: "  - &${alias} ${recipient}";
  renderRule = pathRegex: aliases: ''
      - path_regex: ${pathRegex}
        key_groups:
          - age:
    ${renderAgeList aliases}
  '';
  renderScopedRules =
    scopeName: extensionPattern: scopes:
    let
      names = sort (builtins.attrNames scopes);
    in
    builtins.concatStringsSep "\n" (
      map (
        name:
        let
          hosts = sort scopes.${name}.hosts;
        in
        renderRule "^secrets/${scopeName}/${name}/.*\\.${extensionPattern}$" ([ operatorAlias ] ++ hosts)
      ) names
    );
  renderSopsConfig =
    policy:
    let
      policyHostNames = sort (builtins.attrNames policy.hosts);
      keys = [
        (renderKeyLine policy.operator.alias (builtins.head policy.operator.recipients))
      ]
      ++ map (host: renderKeyLine host policy.hosts.${host}.recipient) policyHostNames;
      userRules = renderScopedRules "users" "(yaml|yml)" policy.scopes.users;
      serviceRules = renderScopedRules "services" "(yaml|yml|json|env|ini)" policy.scopes.services;
      machineRules = builtins.concatStringsSep "\n" (
        map (
          host:
          renderRule "^secrets/machines/${host}/.*\\.(yaml|yml|json|env|ini)$" [
            policy.operator.alias
            host
          ]
        ) policyHostNames
      );
    in
    builtins.concatStringsSep "\n" [
      "keys:"
      (builtins.concatStringsSep "\n" keys)
      "creation_rules:"
      userRules
      serviceRules
      machineRules
      ""
    ];
in
{
  flake.lib = {
    inherit secretsPolicy renderSopsConfig;
    renderedSopsConfig = renderSopsConfig secretsPolicy;

    # Helper function to create a NixOS system configuration.
    # Machine behavior is assembled from explicit capability modules.
    mkNixosSystem =
      {
        system,
        hostname,
        modules ? [ ],
        extraSpecialArgs ? { },
      }:
      let
        # Prefer an explicit live checkout path when provided. Fall back to the
        # flake source path so evaluation still works in pure contexts.
        repoRoot = repoRootDefault;
        dotfilesRoot = "${repoRoot}/dotfiles";
      in
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Machine-specific hardware and config
          ../nixos/machines/${hostname} # This is where the default.nix for the host is imported

          # Flatpak support
          nix-flatpak.nixosModules.nix-flatpak
          sops-nix.nixosModules.sops

          # Global Nix daemon settings
          ../modules/nixos/system/devenv.nix
          ../modules/nixos/system/nix-settings.nix
          ../modules/nixos/system/secrets.nix
          ../modules/nixos/users/djoolz/default.nix
          ../modules/nixos/users/djoolz/ssh.nix
          { nixpkgs.config.allowUnfree = true; }
        ]
        ++ modules;

        specialArgs = {
          inherit
            inputs
            hostname
            repoRoot
            dotfilesRoot
            ;
          pkgs-unstable = mkPkgs nixpkgs-unstable system;
        }
        // extraSpecialArgs;
      };
  };
}
