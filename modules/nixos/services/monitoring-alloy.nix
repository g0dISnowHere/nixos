{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.monitoring;
  textfileDirectory = "/var/lib/prometheus-node-exporter-textfile";
  importantUnitRegex = lib.concatStringsSep "|" cfg.importantUnits;
  nixosStateWriter = pkgs.writeShellApplication {
    name = "monitoring-nixos-state";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
    ];
    text = ''
      set -eu
      output="${textfileDirectory}/nixos_state.prom"
      temporary="$output.$$"
      escape_label() {
        printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
      }
      generation="$(readlink /nix/var/nix/profiles/system | sed -n 's/.*system-\([0-9][0-9]*\)-link/\1/p')"
      revision="$(/run/current-system/sw/bin/nixos-version --configuration-revision 2>/dev/null || true)"
      kernel="$(uname -r)"
      current="$(readlink -f /run/current-system)"
      booted="$(readlink -f /run/booted-system 2>/dev/null || printf '%s' "$current")"
      pending_reboot=0
      [ "$current" = "$booted" ] || pending_reboot=1
      {
        printf 'nixos_system_info{generation="%s",revision="%s",kernel="%s"} 1\n' \
          "$(escape_label "$generation")" "$(escape_label "$revision")" "$(escape_label "$kernel")"
        printf 'nixos_pending_reboot %s\n' "$pending_reboot"
        printf 'monitoring_config_info{revision="%s"} 1\n' "$(escape_label "$revision")"
      } > "$temporary"
      mv "$temporary" "$output"
    '';
  };
in
{
  options.my.monitoring = {
    enable = lib.mkEnableOption "native Alloy monitoring";

    site = lib.mkOption {
      type = lib.types.str;
      example = "vps";
      description = "Stable physical or logical site label.";
    };

    environment = lib.mkOption {
      type = lib.types.str;
      default = "prod";
      description = "Stable deployment environment label.";
    };

    importantUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "sshd.service"
        "alloy.service"
        "tailscaled.service"
        "docker.service"
        "traefik.service"
        "crowdsec.service"
        "prometheus-node-exporter.service"
        "prometheus-systemd-exporter.service"
        "cadvisor.service"
      ];
      description = "Journal units retained regardless of priority.";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      alloy.enable = true;

      prometheus.exporters.node = {
        enabledCollectors = [ "textfile" ];
        extraFlags = [ "--collector.textfile.directory=${textfileDirectory}" ];
      };

      cadvisor = {
        enable = true;
        port = 8081;
        extraOptions = [
          "--docker_only=true"
          "--store_container_labels=false"
          "--whitelisted_container_labels=com.docker.compose.project,com.docker.compose.service"
        ];
      };
    };

    environment.etc."alloy/config.alloy".text = ''
      logging {
        level  = "info"
        format = "logfmt"
      }

      prometheus.remote_write "remote" {
        endpoint {
          url = "https://prometheus.int.djoolz.de/api/v1/write"
        }
      }

      prometheus.scrape "node" {
        targets = [{
          __address__ = "127.0.0.1:9100",
          job = "node-hosts",
          host = "${config.networking.hostName}",
          site = "${cfg.site}",
          environment = "${cfg.environment}",
        }]
        forward_to = [prometheus.remote_write.remote.receiver]
      }

      prometheus.scrape "systemd" {
        targets = [{
          __address__ = "127.0.0.1:9558",
          job = "systemd-hosts",
          host = "${config.networking.hostName}",
          site = "${cfg.site}",
          environment = "${cfg.environment}",
        }]
        forward_to = [prometheus.remote_write.remote.receiver]
      }

      prometheus.scrape "cadvisor" {
        targets = [{
          __address__ = "127.0.0.1:8081",
          job = "cadvisor-hosts",
          host = "${config.networking.hostName}",
          site = "${cfg.site}",
          environment = "${cfg.environment}",
        }]
        forward_to = [prometheus.remote_write.remote.receiver]
      }

      loki.write "remote" {
        endpoint {
          url = "https://loki.int.djoolz.de/loki/api/v1/push"
        }
      }

      loki.relabel "journal" {
        forward_to = [loki.process.filter.receiver]

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label = "unit"
        }
        rule {
          source_labels = ["__journal_priority"]
          target_label = "severity"
        }
      }

      loki.process "filter" {
        forward_to = [loki.relabel.labels.receiver]

        stage.match {
          selector = "{severity!~\"0|1|2|3|4\", unit!~\"${importantUnitRegex}\"}"
          action = "drop"
        }
      }

      loki.relabel "labels" {
        forward_to = [loki.write.remote.receiver]

        rule {
          action = "labelkeep"
          regex = "host|site|environment|source|unit"
        }
      }

      loki.source.journal "journal" {
        forward_to = [loki.process.filter.receiver]
        relabel_rules = loki.relabel.journal.rules
        max_age = "12h"

        labels = {
          host = "${config.networking.hostName}",
          site = "${cfg.site}",
          environment = "${cfg.environment}",
          source = "journald",
        }
      }
    '';

    systemd = {
      tmpfiles.rules = [
        "d ${textfileDirectory} 0755 root root -"
      ];

      services.monitoring-nixos-state = {
        description = "Write NixOS state metrics";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${nixosStateWriter}/bin/monitoring-nixos-state";
        };
      };

      timers.monitoring-nixos-state = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "15min";
        };
      };
    };
  };
}
