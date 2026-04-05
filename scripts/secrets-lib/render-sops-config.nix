let
  policy = import ../../flake/secrets-policy.nix;
  sort = builtins.sort builtins.lessThan;
  operatorRecipientAliases = let
    recipients = policy.operator.recipients;
    count = builtins.length recipients;
    mkAlias = index:
      if index == 0 then
        policy.operator.alias
      else
        "${policy.operator.alias}_${toString index}";
  in map mkAlias (builtins.genList (index: index) count);
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
      (operatorRecipientAliases ++ hosts)) names);
  renderMachineRules = builtins.concatStringsSep "\n" (map (host:
    renderRule "^secrets/machines/${host}/.*\\.(yaml|json|env|ini)$"
    (operatorRecipientAliases ++ [ host ]))
    (sort (builtins.attrNames policy.hosts)));
  operatorKeys = builtins.genList (index:
    renderKeyLine (builtins.elemAt operatorRecipientAliases index)
    (builtins.elemAt policy.operator.recipients index))
    (builtins.length policy.operator.recipients);
  keys = operatorKeys
    ++ map (host: renderKeyLine host policy.hosts.${host}.recipient)
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
