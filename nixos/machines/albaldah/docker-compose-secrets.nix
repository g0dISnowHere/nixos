{ config, lib, ... }:
let
  dockerUser = "djoolz";

  traefikCloudflareSecretFile =
    ../../../secrets/services/traefik/cloudflare-dns-token.yaml;
  traefikCrowdsecLapiKeySecretFile =
    ../../../secrets/services/traefik/crowdsec-lapi-key.yaml;

  hasTraefikCloudflareSecret = builtins.pathExists traefikCloudflareSecretFile;
  hasTraefikCrowdsecLapiKeySecret =
    builtins.pathExists traefikCrowdsecLapiKeySecretFile;
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
  };
}
