{ config, lib, pkgs, ... }:
let
  dockerUser = "djoolz";

  traefikCloudflareSecretFile = ../../../secrets/services/traefik/cloudflare-dns-token.yaml;
  traefikCrowdsecLapiKeySecretFile = ../../../secrets/services/traefik/crowdsec-lapi-key.yaml;
  monitoringGrafanaAdminPasswordSecretFile = ../../../secrets/services/monitoring/grafana-admin-password.yaml;
  monitoringAlertmanagerSmtpPasswordSecretFile = ../../../secrets/services/monitoring/alertmanager-smtp-password.yaml;
  litellmSecretFile = ../../../secrets/services/litellm/secret.yaml;
  pangolinConfigSecretFile = ../../../secrets/services/pangolin/config.yaml;
  pangolinSiteSecretFile = ../../../secrets/services/pangolin/site-albaldah.yaml;

  hasTraefikCloudflareSecret = builtins.pathExists traefikCloudflareSecretFile;
  hasTraefikCrowdsecLapiKeySecret = builtins.pathExists traefikCrowdsecLapiKeySecretFile;
  hasMonitoringGrafanaAdminPasswordSecret = builtins.pathExists monitoringGrafanaAdminPasswordSecretFile;
  hasMonitoringAlertmanagerSmtpPasswordSecret = builtins.pathExists monitoringAlertmanagerSmtpPasswordSecretFile;
  hasLitellmSecret = builtins.pathExists litellmSecretFile;
  hasPangolinConfigSecret = builtins.pathExists pangolinConfigSecretFile;
  hasPangolinSiteSecret = builtins.pathExists pangolinSiteSecretFile;
in
{
  sops.secrets = lib.mkMerge [
    (lib.mkIf hasTraefikCloudflareSecret {
      "traefik-cloudflare-dns-token" = {
        sopsFile = traefikCloudflareSecretFile;
        format = "yaml";
        key = "secret";
        owner = dockerUser;
        mode = "0400";
      };
    })
    (lib.mkIf hasTraefikCrowdsecLapiKeySecret {
      "traefik-crowdsec-lapi-key" = {
        sopsFile = traefikCrowdsecLapiKeySecretFile;
        format = "yaml";
        key = "key";
        owner = dockerUser;
        mode = "0400";
      };
    })
    (lib.mkIf hasMonitoringGrafanaAdminPasswordSecret {
      "monitoring-grafana-admin-password" = {
        sopsFile = monitoringGrafanaAdminPasswordSecretFile;
        format = "yaml";
        key = "secret";
        owner = dockerUser;
        mode = "0400";
      };
    })
    (lib.mkIf hasMonitoringAlertmanagerSmtpPasswordSecret {
      "monitoring-alertmanager-smtp-password" = {
        sopsFile = monitoringAlertmanagerSmtpPasswordSecretFile;
        format = "yaml";
        key = "secret";
        owner = dockerUser;
        mode = "0400";
      };
    })
    (lib.mkIf hasLitellmSecret {
      "litellm-master-key" = {
        sopsFile = litellmSecretFile;
        format = "yaml";
        key = "master_key";
        owner = dockerUser;
        mode = "0400";
      };
      "litellm-salt-key" = {
        sopsFile = litellmSecretFile;
        format = "yaml";
        key = "salt_key";
        owner = dockerUser;
        mode = "0400";
      };
      "litellm-postgres-password" = {
        sopsFile = litellmSecretFile;
        format = "yaml";
        key = "postgres_password";
        owner = dockerUser;
        mode = "0400";
      };
    })
    (lib.mkIf hasPangolinConfigSecret {
      "pangolin-config" = {
        sopsFile = pangolinConfigSecretFile;
        # Pangolin consumes the complete YAML document as its server config.
        key = "";
        format = "yaml";
        owner = dockerUser;
        mode = "0400";
        path = "/run/secrets/pangolin/config.yml";
      };
    })
    (lib.mkIf hasPangolinSiteSecret {
      "pangolin-site-albaldah-env" = {
        sopsFile = pangolinSiteSecretFile;
        format = "yaml";
        key = "env";
        owner = dockerUser;
        mode = "0400";
      };
    })
  ];

  sops.templates = {
    "docker-traefik-env" = {
      path = "/run/secrets/traefik/env";
      owner = dockerUser;
      mode = "0400";
      content = lib.concatStrings [
        (lib.optionalString hasTraefikCloudflareSecret ''
          CF_DNS_API_TOKEN=${config.sops.placeholder."traefik-cloudflare-dns-token"}
        '')
      ];
    };

    "docker-traefik-crowdsec-env" = {
      path = "/run/secrets/traefik/crowdsec.env";
      owner = dockerUser;
      mode = "0400";
      content = lib.concatStrings [
        (lib.optionalString hasTraefikCrowdsecLapiKeySecret ''
          CROWDSEC_LAPI_KEY=${config.sops.placeholder."traefik-crowdsec-lapi-key"}
        '')
      ];
    };

    "docker-nextcloud-aio-env" = {
      path = "/run/secrets/nextcloud-aio/env";
      owner = dockerUser;
      mode = "0400";
      content = "";
    };

    "docker-monitoring-env" = {
      path = "/run/secrets/monitoring/env";
      owner = dockerUser;
      mode = "0400";
      content = lib.concatStrings [
        (lib.optionalString hasMonitoringGrafanaAdminPasswordSecret ''
          GF_SECURITY_ADMIN_PASSWORD=${config.sops.placeholder."monitoring-grafana-admin-password"}
        '')
        (lib.optionalString hasMonitoringAlertmanagerSmtpPasswordSecret ''
          ALERTMANAGER_SMTP_PASSWORD=${config.sops.placeholder."monitoring-alertmanager-smtp-password"}
        '')
      ];
    };
    "docker-litellm-env" = {
      path = "/run/secrets/litellm/litellm.env";
      owner = dockerUser;
      mode = "0400";
      content = lib.concatStrings [
        (lib.optionalString hasLitellmSecret ''
          LITELLM_MASTER_KEY=${config.sops.placeholder."litellm-master-key"}
          LITELLM_SALT_KEY=${config.sops.placeholder."litellm-salt-key"}
          POSTGRES_PASSWORD=${config.sops.placeholder."litellm-postgres-password"}
          DATABASE_URL=postgresql://litellm:${config.sops.placeholder."litellm-postgres-password"}@litellm-db:5432/litellm
        '')
      ];
    };
    "docker-pangolin-site-albaldah-env" = {
      path = "/run/secrets/pangolin/site-albaldah.env";
      owner = dockerUser;
      mode = "0400";
      content = lib.optionalString hasPangolinSiteSecret
        config.sops.placeholder."pangolin-site-albaldah-env";
    };

  };
  systemd.services.litellm-backup = {
    description = "Back up LiteLLM PostgreSQL database";
    serviceConfig = {
      Type = "oneshot";
      User = dockerUser;
      ExecStart = "${pkgs.bash}/bin/bash /home/djoolz/docker/stacks/litellm/scripts/backup.sh";
      Environment = "PATH=${lib.makeBinPath [ pkgs.docker pkgs.coreutils ]}";
    };
  };

  systemd.timers.litellm-backup = {
    description = "Daily LiteLLM PostgreSQL backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "15m";
      Unit = "litellm-backup.service";
    };
  };
}
