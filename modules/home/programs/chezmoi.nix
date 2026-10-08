{
  config,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:
let
  secretNames = [
    "djoolz-gh-hosts"
    "djoolz-opencode-auth"
    "djoolz-orca-ender3-04"
    "djoolz-orca-ender3-06"
    "djoolz-orca-magicianx-04"
    "djoolz-orca-magicianx-06"
    "djoolz-prusa-presets"
  ];
  declaredSecrets = if osConfig == null then { } else osConfig.sops.secrets or { };
  expectedSecrets = builtins.filter (path: path != null) (
    map (
      name: if builtins.hasAttr name declaredSecrets then declaredSecrets.${name}.path else null
    ) secretNames
  );
  githubHosts =
    if builtins.hasAttr "djoolz-gh-hosts" declaredSecrets then
      declaredSecrets."djoolz-gh-hosts".path
    else
      null;
  enabled = config.home.username == "djoolz";
  syncEnvironment =
    lib.optionalAttrs (osConfig != null) {
      CHEZMOI_EXPECTED_SECRETS = builtins.toJSON expectedSecrets;
    }
    // lib.optionalAttrs (githubHosts != null) {
      CHEZMOI_GH_HOSTS = githubHosts;
    };
  quoteSystemd = value: "\"${builtins.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] value}\"";
  sync = pkgs.writeShellApplication {
    name = "chezmoi-sync";
    runtimeInputs = [
      pkgs.chezmoi
      pkgs.coreutils
      pkgs.git
      pkgs.gh
      pkgs.inetutils
      pkgs.procps
      pkgs.python3
    ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${pkgs.writeText "chezmoi-sync.py" (builtins.readFile ./chezmoi-sync.py)}
    '';
  };
in
{
  home.packages = [
    pkgs.chezmoi
    pkgs.sops
  ];

  systemd.user = lib.mkIf enabled {
    services.chezmoi-sync = {
      Unit = {
        Description = "Synchronize native settings through chezmoi";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        Environment = lib.mapAttrsToList (name: value: quoteSystemd "${name}=${value}") syncEnvironment;
        ExecStart = "${sync}/bin/chezmoi-sync";
      };
    };
    timers.chezmoi-sync = {
      Unit.Description = "Synchronize native settings every five minutes";
      Timer = {
        OnBootSec = "5m";
        OnUnitActiveSec = "5m";
        Unit = "chezmoi-sync.service";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
