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
  publicFirewallPorts = lib.unique (
    let
      ports = protocol: entries: map (port: { inherit protocol port; }) entries;
      portRanges =
        protocol: ranges: lib.concatMap (range: ports protocol (lib.range range.from range.to)) ranges;
    in
    ports "tcp" config.networking.firewall.allowedTCPPorts
    ++ ports "udp" config.networking.firewall.allowedUDPPorts
    ++ portRanges "tcp" config.networking.firewall.allowedTCPPortRanges
    ++ portRanges "udp" config.networking.firewall.allowedUDPPortRanges
  );
  firewallPortMetrics = lib.concatMapStrings (entry: ''
    printf 'nixos_firewall_allowed_port_info{protocol="${entry.protocol}",port="${toString entry.port}"} 1\n'
  '') publicFirewallPorts;

  nixosStateWriter = pkgs.writeShellApplication {
    name = "monitoring-nixos-state";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.docker
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
        printf 'nixos_firewall_allowed_port_count %s\n' ${toString (builtins.length publicFirewallPorts)}
        ${firewallPortMetrics}
        if docker info >/dev/null 2>&1; then
          docker ps --format '{{.ID}}' | while read -r container_id; do
            docker inspect --format '{{range $container_port, $bindings := .HostConfig.PortBindings}}{{range $bindings}}{{printf "%s|%s|%s|%s|%s\n" $container_port .HostIp .HostPort (index $.Config.Labels "com.docker.compose.service") (index $.Config.Labels "com.docker.compose.project")}}{{end}}{{end}}' "$container_id"
          done | while IFS='|' read -r container_port host_ip host_port service compose_project; do
            case "$host_ip" in
              ""|0.0.0.0|::)
                protocol="$(printf '%s' "$container_port" | sed 's#.*/##')"
                [ "$service" = "<no value>" ] && service="container"
                [ "$compose_project" = "<no value>" ] && compose_project="unknown"
                printf 'docker_public_published_port_info{protocol="%s",port="%s",service="%s",compose_project="%s"} 1\n' \
                  "$protocol" "$host_port" "$(escape_label "$service")" "$(escape_label "$compose_project")"
                ;;
            esac
          done
        fi
      } > "$temporary"
      mv "$temporary" "$output"
    '';
  };
  wanReachabilityWriter = pkgs.writeShellApplication {
    name = "monitoring-wan-reachability";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.glibc
      pkgs.iputils
    ];
    text = ''
      set -eu
      output="${textfileDirectory}/wan_reachability.prom"
      temporary="$output.$$"
      wan_reachable=0
      dns_reachable=0

      ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 && wan_reachable=1
      getent ahostsv4 one.one.one.one >/dev/null 2>&1 && dns_reachable=1

      {
        printf 'monitoring_wan_reachable %s\n' "$wan_reachable"
        printf 'monitoring_dns_reachable %s\n' "$dns_reachable"
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

    openwrtTarget = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "LAN OpenWrt exporter target scraped by this Alloy relay.";
    };

    openwrtHost = lib.mkOption {
      type = lib.types.str;
      default = "auriga";
      description = "Stable host label for the LAN OpenWrt exporter and syslog.";
    };

    wanProbe = lib.mkEnableOption "LAN WAN and DNS reachability metrics";

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
      alloy.extraFlags = [ "--stability.level=experimental" ];

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

      ${lib.optionalString (cfg.openwrtTarget != null) ''
        prometheus.scrape "openwrt" {
          targets = [{
            __address__ = "${cfg.openwrtTarget}",
            job = "openwrt",
            host = "${cfg.openwrtHost}",
            site = "${cfg.site}",
            environment = "${cfg.environment}",
          }]
          forward_to = [prometheus.remote_write.remote.receiver]
        }
      ''}


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

      prometheus.scrape "alloy" {
        targets = [{
          __address__ = "127.0.0.1:12345",
          job = "alloy",
          host = "${config.networking.hostName}",
          site = "${cfg.site}",
          environment = "${cfg.environment}",
        }]
        forward_to = [prometheus.remote_write.remote.receiver]
      }

      loki.write "remote" {
        endpoint {
          url = "https://loki.int.djoolz.de/loki/api/v1/push"
          max_backoff_retries = 0
        }

        wal {
          enabled = true
          max_segment_age = "168h"
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

      ${lib.optionalString (cfg.openwrtTarget != null) ''
        loki.source.file "openwrt_syslog" {
          targets = [{
            __path__ = "/var/log/remote/*/*.log",
            host = "${cfg.openwrtHost}",
            site = "${cfg.site}",
            environment = "${cfg.environment}",
            source = "openwrt_syslog",
          }]
          forward_to = [loki.relabel.labels.receiver]
          tail_from_end = true

          file_match {
            enabled = true
          }
        }
      ''}
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

      services.monitoring-wan-reachability = lib.mkIf cfg.wanProbe {
        description = "Write LAN WAN and DNS reachability metrics";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${wanReachabilityWriter}/bin/monitoring-wan-reachability";
        };
      };

      timers.monitoring-wan-reachability = lib.mkIf cfg.wanProbe {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "1min";
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
