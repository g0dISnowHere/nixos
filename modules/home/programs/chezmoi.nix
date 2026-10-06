{
  config,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:
let
  hostNames = [
    "albaldah"
    "alhena"
    "centauri"
    "karaka"
    "mirach"
  ];
  enabled =
    config.home.username == "djoolz"
    && osConfig != null
    && builtins.elem osConfig.networking.hostName hostNames;
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
