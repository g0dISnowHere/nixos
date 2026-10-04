{
  config,
  lib,
  pkgs,
  ...
}:
let
  secretFile = ../../../secrets/services/pangolin/newt/centauri.yaml;
  hasSecret = builtins.pathExists secretFile;
in
lib.mkIf hasSecret {
  sops.secrets.pangolin-newt-env = {
    sopsFile = secretFile;
    format = "yaml";
    key = "env";
    owner = "root";
    mode = "0400";
  };

  sops.templates.pangolin-newt-env = {
    path = "/run/secrets/pangolin/newt.env";
    owner = "root";
    content = config.sops.placeholder."pangolin-newt-env";
  };

  systemd.services.pangolin-newt = {
    description = "Pangolin Newt connector";
    wants = [ "network-online.target" ];
    requires = [ "sops-install-secrets.service" ];
    after = [
      "network-online.target"
      "sops-install-secrets.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      EnvironmentFile = "/run/secrets/pangolin/newt.env";
      ExecStart = "${pkgs.fosrl-newt}/bin/newt";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
