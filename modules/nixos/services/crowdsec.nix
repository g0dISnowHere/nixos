{ config, lib, pkgs, pkgs-unstable, ... }:
let
  format = pkgs.formats.yaml { };
  # CrowdSec has 3 separate remote auth domains here:
  # 1. Console enrollment token: one-time / revocable attachment token
  # 2. CTI API key: threat-intel enrichment API key
  # 3. CAPI runtime credentials: generated or imported machine credentials for
  #    the Central API
  consoleTokenSecretFile =
    ../../../secrets/services/crowdsec/console-enrollment-token.yaml;
  ctiApiKeySecretFile = ../../../secrets/services/crowdsec/cti-api-key.yaml;
  importedCapiCredentialsSecretFile =
    ../../../secrets/services/crowdsec/online-api-credentials.yaml;

  hasConsoleToken = builtins.pathExists consoleTokenSecretFile;
  hasCtiApiKey = builtins.pathExists ctiApiKeySecretFile;
  hasImportedCapiCredentials =
    builtins.pathExists importedCapiCredentialsSecretFile;

  crowdsecStateDir = "/var/lib/crowdsec";
  crowdsecHubStateDir = "${crowdsecStateDir}/state/hub";
  localApiCredentialsPath = "${crowdsecStateDir}/local_api_credentials.yaml";
  onlineApiCredentialsPath = if hasImportedCapiCredentials then
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

  cscliBasePath = lib.getExe' config.services.crowdsec.package "cscli";
  cscliConfigArgs = lib.optionalString hasCtiApiKey
    " -c ${config.sops.templates."crowdsec-config.yaml".path}";
  cscliPath =
    "${config.security.wrapperDir}/sudo -u ${config.services.crowdsec.user} ${cscliBasePath}${cscliConfigArgs}";
  cscliRegisterPath = "${cscliBasePath}${cscliConfigArgs}";
  dockerIngressCidrs =
    [ "172.17.0.0/16" "172.30.0.0/16" "172.31.0.0/16" "172.32.0.0/16" ];
  dockerIngressInterfaces = [ "docker0" "br-*" ];
  traefikAccessLogPath = "/var/log/traefik/access.log";
  firewallBouncerApiKeyPath =
    "/var/lib/crowdsec-firewall-bouncer-register/api-key.cred";
  reRegisterFirewallBouncer =
    pkgs.writeShellScript "crowdsec-firewall-bouncer-register-local" ''
      set -euo pipefail

      cscli=${lib.escapeShellArg cscliRegisterPath}
      bouncer_name=crowdsec-firewall-bouncer
      tmp_key="$(mktemp)"
      trap 'rm -f "$tmp_key"' EXIT

      if $cscli bouncers list --output json | ${
        lib.getExe pkgs.jq
      } -e -- "any(.[]; .name == \"$bouncer_name\")" >/dev/null; then
        if [ ! -s ${lib.escapeShellArg firewallBouncerApiKeyPath} ]; then
          $cscli bouncers delete "$bouncer_name" || true
          rm -f ${lib.escapeShellArg firewallBouncerApiKeyPath}
          $cscli bouncers add --output raw "$bouncer_name" >"$tmp_key"
          test -s "$tmp_key"
          install -D -m 0600 -o ${
            lib.escapeShellArg config.services.crowdsec.user
          } -g ${
            lib.escapeShellArg config.services.crowdsec.group
          } "$tmp_key" ${lib.escapeShellArg firewallBouncerApiKeyPath}
        fi
      else
        rm -f ${lib.escapeShellArg firewallBouncerApiKeyPath}
        $cscli bouncers add --output raw "$bouncer_name" >"$tmp_key"
        test -s "$tmp_key"
        install -D -m 0600 -o ${
          lib.escapeShellArg config.services.crowdsec.user
        } -g ${lib.escapeShellArg config.services.crowdsec.group} "$tmp_key" ${
          lib.escapeShellArg firewallBouncerApiKeyPath
        }
      fi
    '';
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
    (lib.mkIf hasImportedCapiCredentials {
      "crowdsec-online-api-credentials" = {
        sopsFile = importedCapiCredentialsSecretFile;
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
    package = pkgs-unstable.crowdsec;

    hub.appSecConfigs = [ "crowdsecurity/appsec-default" ];

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

    localConfig.acquisitions = [
      {
        source = "journalctl";
        journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
        labels.type = "syslog";
      }
      {
        filenames = [ traefikAccessLogPath ];
        labels.type = "traefik";
      }
      {
        appsec_configs = [ "crowdsecurity/appsec-default" ];
        labels.type = "appsec";
        listen_addr = "0.0.0.0:7422";
        source = "appsec";
      }
    ];

    settings = {
      lapi.credentialsFile = localApiCredentialsPath;

      general.api.server = {
        enable = true;
        listen_uri = "0.0.0.0:8080";
        console_path = consoleConfigPath;
        online_client.credentials_path = onlineApiCredentialsPath;
      };
    };
  };

  services.crowdsec-firewall-bouncer.enable = true;
  services.crowdsec-firewall-bouncer.settings.iptables_chains =
    [ "INPUT" "DOCKER-USER" ];

  # Keep service-readable ingress logs out of user homes because crowdsec runs
  # with ProtectHome and should not depend on traversing /home.
  systemd.tmpfiles.rules = [ "d /var/log/traefik 0755 root root -" ];

  networking.firewall.extraInputRules = ''
    ip saddr { ${
      lib.concatStringsSep ", " dockerIngressCidrs
    } } tcp dport { 8080, 7422 } accept comment "allow Docker stacks to reach CrowdSec LAPI and AppSec"
    iifname { ${
      lib.concatStringsSep ", "
      (map (iface: ''"${iface}"'') dockerIngressInterfaces)
    } } tcp dport { 8080, 7422 } accept comment "allow Docker bridge interfaces to reach CrowdSec LAPI and AppSec"
  '';

  networking.firewall.extraCommands = ''
    ${lib.concatMapStringsSep "\n" (cidr: ''
      iptables -C nixos-fw -s ${cidr} -p tcp -m multiport --dports 8080,7422 -j nixos-fw-accept 2>/dev/null \
        || iptables -I nixos-fw 3 -s ${cidr} -p tcp -m multiport --dports 8080,7422 -j nixos-fw-accept
    '') dockerIngressCidrs}
  '';

  networking.firewall.extraStopCommands = ''
    ${lib.concatMapStringsSep "\n" (cidr: ''
      iptables -D nixos-fw -s ${cidr} -p tcp -m multiport --dports 8080,7422 -j nixos-fw-accept 2>/dev/null || true
    '') dockerIngressCidrs}
  '';

  systemd.services = {
    crowdsec.serviceConfig.ExecStart = lib.mkIf hasCtiApiKey (lib.mkForce [
      " "
      "${lib.getExe' config.services.crowdsec.package "crowdsec"} -c ${
        config.sops.templates."crowdsec-config.yaml".path
      } -info"
    ]);
    crowdsec.serviceConfig = {
      DynamicUser = lib.mkForce false;
      # CrowdSec's journalctl datasource exits immediately inside the service's
      # user namespace even when the runtime user is in systemd-journal.
      # Keep journal access working so SSH ingestion does not tear down AppSec
      # and file datasources on startup.
      PrivateUsers = lib.mkForce false;
      StateDirectory = "crowdsec";
      SupplementaryGroups = [ "systemd-journal" ];
    };
    crowdsec.serviceConfig.ExecStartPre = lib.mkForce [
      " "
      (pkgs.writeShellScript "crowdsec-prestart" ''
        set -euo pipefail

        ${lib.getExe' pkgs.coreutils "mkdir"} -p \
          ${lib.escapeShellArg crowdsecHubStateDir}
      '')
      "${lib.getExe' config.services.crowdsec.package "crowdsec"} -c ${
        if hasCtiApiKey then
          config.sops.templates."crowdsec-config.yaml".path
        else
          "/etc/crowdsec/config.yaml"
      } -t -error"
    ];
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

    crowdsec-capi-register = lib.mkIf (!hasImportedCapiCredentials) {
      description = "Register CrowdSec Central API runtime credentials";
      wantedBy = [ "multi-user.target" ];
      after = [ "crowdsec.service" "network-online.target" ];
      wants = [ "crowdsec.service" "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
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
        ExecStart = pkgs.writeShellScript "crowdsec-console-enroll" ''
          set -euo pipefail

          ${lib.getExe' pkgs.coreutils "mkdir"} -p \
            ${lib.escapeShellArg crowdsecHubStateDir}
          ${lib.getExe' pkgs.coreutils "chown"} -R ${
            lib.escapeShellArg
            "${config.services.crowdsec.user}:${config.services.crowdsec.group}"
          } ${lib.escapeShellArg crowdsecStateDir}

          if [ ! -r ${
            lib.escapeShellArg "${crowdsecHubStateDir}/.index.json"
          } ]; then
            ${cscliPath} hub update
          fi

          if ${lib.getExe pkgs.gnugrep} -q '^enroll_key:' ${
            lib.escapeShellArg consoleConfigPath
          }; then
            exit 0
          fi

          token="$(cat ${lib.escapeShellArg consoleEnrollTokenPath})"
          tmp_output="$(mktemp)"
          trap 'rm -f "$tmp_output"' EXIT

          if ${cscliPath} console enroll "$token" --name ${
            lib.escapeShellArg config.networking.hostName
          } >"$tmp_output" 2>&1; then
            cat "$tmp_output"
            exit 0
          fi

          cat "$tmp_output" >&2

          # Enrollment tokens are single-use / revocable in the Console. A
          # stale token should not block an otherwise healthy system switch.
          if ${
            lib.getExe pkgs.gnugrep
          } -q 'API error: Forbidden' "$tmp_output"; then
            echo "crowdsec-console-enroll: stale or revoked enrollment token, leaving Console enrollment unchanged" >&2
            exit 0
          fi

          exit 1
        '';
      };
    };

    crowdsec-firewall-bouncer-register.after =
      lib.mkIf (!hasImportedCapiCredentials)
      [ "crowdsec-capi-register.service" ];
    crowdsec-firewall-bouncer-register.requires =
      lib.mkIf (!hasImportedCapiCredentials)
      [ "crowdsec-capi-register.service" ];
    crowdsec-firewall-bouncer-register.script =
      lib.mkForce (builtins.readFile reRegisterFirewallBouncer);
  };
}
