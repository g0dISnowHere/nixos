let
  policy = import ../../flake/secrets-policy.nix;
  sort = builtins.sort builtins.lessThan;
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
      ([ policy.operator.alias ] ++ hosts)) names);
  renderMachineRules = builtins.concatStringsSep "\n" (map (host:
    renderRule "^secrets/machines/${host}/.*\\.(yaml|json|env|ini)$" [
      policy.operator.alias
      host
    ]) (sort (builtins.attrNames policy.hosts)));
  keys = [
    (renderKeyLine policy.operator.alias
      (builtins.head policy.operator.recipients))
  ] ++ map (host: renderKeyLine host policy.hosts.${host}.recipient)
    (sort (builtins.attrNames policy.hosts));
in builtins.concatStringsSep "\n" [
  "keys:"
  (builtins.concatStringsSep "\n" keys)
  "creation_rules:"
  (renderScopedRules "users" "yaml" policy.scopes.users)
  (renderScopedRules "services" "(yaml|json|env|ini)" policy.scopes.services)
  renderMachineRules
  ""
]
