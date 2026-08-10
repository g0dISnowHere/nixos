{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.autoUpdate;
  username = "djoolz";
  homeDir = lib.attrByPath [ "users" "users" username "home" ] "/home/${username}" config;
  updateScript = pkgs.writeShellApplication {
    name = "update-system";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      git
      hostname
      nix
      shadow
      sudo
    ];
    text = builtins.readFile ../../../scripts/update-system.sh;
  };
  defaultRepoPath = "${homeDir}/nixos-deploy";
in
{
  options.my.autoUpdate = {
    enable = lib.mkEnableOption "scheduled local flake updates";

    repoPath = lib.mkOption {
      type = lib.types.str;
      default = defaultRepoPath;
      description = "Existing Git checkout updated by this host's scheduled job.";
    };

    repoUser = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "User account that owns Git credentials and global tool stores.";
    };

    remote = lib.mkOption {
      type = lib.types.str;
      default = "origin";
      description = "Git remote used by the scheduled update job.";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Git branch the scheduled update job updates.";
    };

    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "systemd timer schedule for the update job.";
    };

    randomizedDelaySec = lib.mkOption {
      type = lib.types.str;
      default = "45min";
      description = "Randomized delay applied to the update timer.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services.auto-update-system = {
        description = "Update and rebuild this NixOS host";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          WorkingDirectory = "/";
        };
        script = ''
          exec ${updateScript}/bin/update-system \
            --host ${config.networking.hostName} \
            --repo ${lib.escapeShellArg cfg.repoPath} \
            --repo-user ${lib.escapeShellArg cfg.repoUser} \
            --remote ${lib.escapeShellArg cfg.remote} \
            --branch ${lib.escapeShellArg cfg.branch}
        '';
      };

      timers.auto-update-system = {
        description = "Schedule local NixOS updates";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.onCalendar;
          RandomizedDelaySec = cfg.randomizedDelaySec;
          Persistent = true;
          Unit = "auto-update-system.service";
        };
      };
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };

    nix.optimise.automatic = true;
  };
}
