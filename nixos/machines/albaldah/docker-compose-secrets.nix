{ config, lib, ... }:
let
  dockerUser = "djoolz";

  traefikCloudflareSecretFile =
    ../../../secrets/services/traefik/cloudflare-dns-token.yaml;
  traefikCrowdsecLapiKeySecretFile =
    ../../../secrets/services/traefik/crowdsec-lapi-key.yaml;
  monitoringGrafanaAdminPasswordSecretFile =
    ../../../secrets/services/monitoring/grafana-admin-password.yaml;
  monitoringAlertmanagerSmtpPasswordSecretFile =
    ../../../secrets/services/monitoring/alertmanager-smtp-password.yaml;

  hasTraefikCloudflareSecret = builtins.pathExists traefikCloudflareSecretFile;
  hasTraefikCrowdsecLapiKeySecret =
    builtins.pathExists traefikCrowdsecLapiKeySecretFile;
  hasMonitoringGrafanaAdminPasswordSecret =
    builtins.pathExists monitoringGrafanaAdminPasswordSecretFile;
  hasMonitoringAlertmanagerSmtpPasswordSecret =
    builtins.pathExists monitoringAlertmanagerSmtpPasswordSecretFile;
in {
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
  ];

  sops.templates = {
    "docker-traefik-env" = {
      path = "/run/secrets/traefik/env";
      owner = dockerUser;
      mode = "0400";
      content = lib.concatStrings [
        (lib.optionalString hasTraefikCloudflareSecret ''
          CF_DNS_API_TOKEN=${
            config.sops.placeholder."traefik-cloudflare-dns-token"
          }
        '')
      ];
    };

    "docker-traefik-crowdsec-env" = {
      path = "/run/secrets/traefik/crowdsec.env";
      owner = dockerUser;
      mode = "0400";
      content = lib.concatStrings [
        (lib.optionalString hasTraefikCrowdsecLapiKeySecret ''
          CROWDSEC_LAPI_KEY=${
            config.sops.placeholder."traefik-crowdsec-lapi-key"
          }
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
          GF_SECURITY_ADMIN_PASSWORD=${
            config.sops.placeholder."monitoring-grafana-admin-password"
          }
        '')
        (lib.optionalString hasMonitoringAlertmanagerSmtpPasswordSecret ''
          ALERTMANAGER_SMTP_PASSWORD=${
            config.sops.placeholder."monitoring-alertmanager-smtp-password"
          }
        '')
      ];
    };
  };
}
