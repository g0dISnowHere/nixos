{ config, lib, pkgs, repoRoot ? null, ... }:

let
  cfg = config.my.autoUpdate;
  username = "djoolz";
  homeDir =
    lib.attrByPath [ "users" "users" username "home" ] "/home/${username}"
    config;
  updateScript = pkgs.writeShellApplication {
    name = "update-system";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      findutils
      gawk
      git
      gnugrep
      gnused
      hostname
      libnotify
      nix
      openssh
      procps
      shadow
      sudo
      systemd
      util-linux
    ];
    text = builtins.readFile ../../../scripts/update-system.sh;
  };
  defaultRepoPath = if repoRoot != null then
    "${homeDir}/nixos-deploy"
  else
    "${homeDir}/nixos-deploy";
  validationModeType = lib.types.enum [ "none" "eval" ];
in {
  options.my.autoUpdate = {
    enable = lib.mkEnableOption "scheduled branch-safe flake updates";

    mode = lib.mkOption {
      type = lib.types.enum [ "updater" "consumer" ];
      default = "consumer";
      description =
        "Whether this host owns flake.lock updates or only consumes origin/main.";
    };

    repoPath = lib.mkOption {
      type = lib.types.str;
      default = defaultRepoPath;
      description = "Live checkout path used by the scheduled update job.";
    };

    repoUser = lib.mkOption {
      type = lib.types.str;
      default = username;
      description =
        "User account that owns git credentials for repo operations.";
    };

    remote = lib.mkOption {
      type = lib.types.str;
      default = "origin";
      description = "Git remote used for scheduled update operations.";
    };

    repoUrl = lib.mkOption {
      type = lib.types.str;
      default = "git@github.com:g0dISnowHere/nixos.git";
      description =
        "Git URL used to bootstrap the deployment checkout when absent.";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Git branch that scheduled jobs are allowed to touch.";
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

    validationMode = lib.mkOption {
      type = validationModeType;
      default = "eval";
      description = "Validation step to run before switching.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.auto-update-bootstrap = {
      description = "Bootstrap deployment checkout for scheduled updates";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig.ConditionPathExists = "!${cfg.repoPath}/.git";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        WorkingDirectory = "/";
      };
      script = ''
        exec ${updateScript}/bin/update-system \
          --mode bootstrap \
          --host ${config.networking.hostName} \
          --repo ${lib.escapeShellArg cfg.repoPath} \
          --repo-user ${lib.escapeShellArg cfg.repoUser} \
          --remote ${lib.escapeShellArg cfg.remote} \
          --repo-url ${lib.escapeShellArg cfg.repoUrl} \
          --branch ${lib.escapeShellArg cfg.branch} \
          --validation-mode ${lib.escapeShellArg cfg.validationMode}
      '';
    };

    systemd.services.auto-update-system = {
      description = "Branch-safe scheduled NixOS update";
      after = [ "network-online.target" "auto-update-bootstrap.service" ];
      wants = [ "network-online.target" "auto-update-bootstrap.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        WorkingDirectory = "/";
      };
      script = ''
        exec ${updateScript}/bin/update-system \
          --mode ${cfg.mode} \
          --host ${config.networking.hostName} \
          --repo ${lib.escapeShellArg cfg.repoPath} \
          --repo-user ${lib.escapeShellArg cfg.repoUser} \
          --remote ${lib.escapeShellArg cfg.remote} \
          --repo-url ${lib.escapeShellArg cfg.repoUrl} \
          --branch ${lib.escapeShellArg cfg.branch} \
          --validation-mode ${lib.escapeShellArg cfg.validationMode}
      '';
    };

    systemd.timers.auto-update-system = {
      description = "Schedule branch-safe NixOS updates";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.onCalendar;
        RandomizedDelaySec = cfg.randomizedDelaySec;
        Persistent = true;
        Unit = "auto-update-system.service";
      };
    };

    system.activationScripts.autoUpdateBootstrap =
      lib.stringAfter [ "users" ] ''
        if [ ! -e ${lib.escapeShellArg "${cfg.repoPath}/.git"} ]; then
          ${pkgs.systemd}/bin/systemd-run \
            --unit=auto-update-bootstrap-activation \
            --description="Bootstrap deployment checkout for scheduled updates" \
            --collect \
            ${updateScript}/bin/update-system \
            --mode bootstrap \
            --host ${config.networking.hostName} \
            --repo ${lib.escapeShellArg cfg.repoPath} \
            --repo-user ${lib.escapeShellArg cfg.repoUser} \
            --remote ${lib.escapeShellArg cfg.remote} \
            --repo-url ${lib.escapeShellArg cfg.repoUrl} \
            --branch ${lib.escapeShellArg cfg.branch} \
            --validation-mode ${lib.escapeShellArg cfg.validationMode} \
            >/dev/null 2>&1 || true
        fi
      '';

    # Also enable garbage collection of old generations.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };

    # Enable automatic nix-store optimisation.
    nix.optimise = { automatic = true; };
  };
}
