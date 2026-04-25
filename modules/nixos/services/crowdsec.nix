{ config, lib, pkgs, ... }:
let
  format = pkgs.formats.yaml { };
  consoleTokenSecretFile =
    ../../../secrets/services/crowdsec/console-enrollment-token.yaml;
  ctiApiKeySecretFile = ../../../secrets/services/crowdsec/cti-api-key.yaml;
  importedOnlineApiSecretFile =
    ../../../secrets/services/crowdsec/online-api-credentials.yaml;

  hasConsoleToken = builtins.pathExists consoleTokenSecretFile;
  hasCtiApiKey = builtins.pathExists ctiApiKeySecretFile;
  hasImportedOnlineApiCredentials =
    builtins.pathExists importedOnlineApiSecretFile;

  crowdsecStateDir = "/var/lib/crowdsec";
  localApiCredentialsPath = "${crowdsecStateDir}/local_api_credentials.yaml";
  onlineApiCredentialsPath = if hasImportedOnlineApiCredentials then
    config.sops.secrets."crowdsec-online-api-credentials".path
  else
    "${crowdsecStateDir}/online_api_credentials.yaml";
  consoleConfigPath = "${crowdsecStateDir}/console.yaml";
  consoleEnrollTokenPath = if hasConsoleToken then
    config.sops.secrets."crowdsec-console-enrollment-token".path
  else
    null;

  consoleDefaultConfig = pkgs.writeText "crowdsec-console.yaml" ''
    share_manual_decisions: false
    share_custom: false
    share_tainted: false
    share_context: false
  '';
  crowdsecConfigWithCti = format.generate "crowdsec-with-cti.yaml"
    (lib.recursiveUpdate config.services.crowdsec.settings.general
      (lib.optionalAttrs hasCtiApiKey {
        api.cti = {
          enabled = true;
          key = config.sops.placeholder."crowdsec-cti-api-key";
          cache_timeout = "60m";
          cache_size = 50;
          log_level = "info";
        };
      }));

  cscliPath =
    "${config.security.wrapperDir}/sudo -u ${config.services.crowdsec.user} /run/current-system/sw/bin/cscli";
in {
  sops.secrets = lib.mkMerge [
    (lib.mkIf hasConsoleToken {
      "crowdsec-console-enrollment-token" = {
        sopsFile = consoleTokenSecretFile;
        format = "yaml";
        key = "token";
        owner = config.services.crowdsec.user;
        group = config.services.crowdsec.group;
        mode = "0400";
      };
    })
    (lib.mkIf hasCtiApiKey {
      "crowdsec-cti-api-key" = {
        sopsFile = ctiApiKeySecretFile;
        format = "yaml";
        key = "key";
        owner = "root";
        mode = "0400";
      };
    })
    (lib.mkIf hasImportedOnlineApiCredentials {
      "crowdsec-online-api-credentials" = {
        sopsFile = importedOnlineApiSecretFile;
        format = "yaml";
        owner = config.services.crowdsec.user;
        group = config.services.crowdsec.group;
        mode = "0400";
      };
    })
  ];

  sops.templates = lib.mkIf hasCtiApiKey {
    "crowdsec-config.yaml" = {
      file = crowdsecConfigWithCti;
      owner = config.services.crowdsec.user;
      group = config.services.crowdsec.group;
      mode = "0400";
      restartUnits = [ "crowdsec.service" ];
    };
  };

  services.crowdsec = {
    enable = true;
    autoUpdateService = true;

    hub.collections = [
      "crowdsecurity/linux"
      "crowdsecurity/traefik"
      "crowdsecurity/nextcloud"
      "crowdsecurity/http-cve"
      "crowdsecurity/appsec-virtual-patching"
      "crowdsecurity/appsec-generic-rules"
      "crowdsecurity/appsec-crs-exclusion-plugin-nextcloud"
      "firix/authentik"
    ];

    localConfig.acquisitions = [{
      source = "journalctl";
      journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
      labels.type = "syslog";
    }];

    settings = {
      lapi.credentialsFile = localApiCredentialsPath;

      general.api.server = {
        enable = true;
        console_path = consoleConfigPath;
        online_client.credentials_path = onlineApiCredentialsPath;
      };
    };
  };

  services.crowdsec-firewall-bouncer.enable = true;

  systemd.services = {
    crowdsec.serviceConfig.ExecStart = lib.mkIf hasCtiApiKey (lib.mkForce [
      " "
      "${lib.getExe' config.services.crowdsec.package "crowdsec"} -c ${
        config.sops.templates."crowdsec-config.yaml".path
      } -info"
    ]);
    crowdsec.serviceConfig.StateDirectory = "crowdsec";
    crowdsec.after = [ "crowdsec-console-config-init.service" ];
    crowdsec.requires = [ "crowdsec-console-config-init.service" ];

    crowdsec-console-config-init = {
      description = "Initialize writable CrowdSec console config";
      wantedBy = [ "multi-user.target" ];
      before = [ "crowdsec.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        StateDirectory = "crowdsec";
        ExecStart = pkgs.writeShellScript "crowdsec-console-config-init" ''
          set -euo pipefail
          ${lib.getExe' pkgs.coreutils "mkdir"} -p \
            ${lib.escapeShellArg crowdsecStateDir} \
            ${lib.escapeShellArg "${crowdsecStateDir}/state"} \
            ${lib.escapeShellArg "${crowdsecStateDir}/state/hub"} \
            ${lib.escapeShellArg "${crowdsecStateDir}/state/trace"}
          ${lib.getExe' pkgs.coreutils "chown"} -R ${
            lib.escapeShellArg
            "${config.services.crowdsec.user}:${config.services.crowdsec.group}"
          } ${lib.escapeShellArg crowdsecStateDir}
          if [ ! -s ${lib.escapeShellArg consoleConfigPath} ]; then
            ${lib.getExe' pkgs.coreutils "install"} -D -m 0600 -o ${
              lib.escapeShellArg config.services.crowdsec.user
            } -g ${lib.escapeShellArg config.services.crowdsec.group} ${
              lib.escapeShellArg consoleDefaultConfig
            } ${lib.escapeShellArg consoleConfigPath}
          fi
        '';
      };
    };

    crowdsec-capi-register = lib.mkIf (!hasImportedOnlineApiCredentials) {
      description = "Register CrowdSec online API credentials";
      wantedBy = [ "multi-user.target" ];
      after = [ "crowdsec.service" "network-online.target" ];
      wants = [ "crowdsec.service" "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        StateDirectory = "crowdsec";
        ExecStart = pkgs.writeShellScript "crowdsec-capi-register" ''
          set -euo pipefail

          if [ -s ${lib.escapeShellArg onlineApiCredentialsPath} ] && ${
            lib.getExe pkgs.gnugrep
          } -q '^password:' ${lib.escapeShellArg onlineApiCredentialsPath}; then
            exit 0
          fi

          ${cscliPath} capi register
        '';
      };
    };

    crowdsec-console-enroll = lib.mkIf hasConsoleToken {
      description = "Enroll CrowdSec instance into CrowdSec Console";
      wantedBy = [ "multi-user.target" ];
      after = [ "crowdsec.service" "network-online.target" ];
      wants = [ "crowdsec.service" "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        StateDirectory = "crowdsec";
        ExecStart = pkgs.writeShellScript "crowdsec-console-enroll" ''
          set -euo pipefail

          if ${lib.getExe pkgs.gnugrep} -q '^enroll_key:' ${
            lib.escapeShellArg consoleConfigPath
          }; then
            exit 0
          fi

          token="$(cat ${lib.escapeShellArg consoleEnrollTokenPath})"
          ${cscliPath} console enroll "$token" --name ${
            lib.escapeShellArg config.networking.hostName
          }
        '';
      };
    };

    crowdsec-firewall-bouncer-register.after =
      lib.mkIf (!hasImportedOnlineApiCredentials)
      [ "crowdsec-capi-register.service" ];
    crowdsec-firewall-bouncer-register.requires =
      lib.mkIf (!hasImportedOnlineApiCredentials)
      [ "crowdsec-capi-register.service" ];
  };
}
