inputs:
inputs."flake-parts".lib.mkFlake { inherit inputs; } {

  imports = [
    # To import a flake module
    # 1. Add foo to inputs
    # 2. Add foo as a parameter to the outputs function
    # 3. Add here: foo.flakeModule

    # Import home-manager's flake module
    inputs.home-manager.flakeModules.home-manager
    inputs.treefmt-nix.flakeModule
    ./parts/formatter.nix
    ./parts/checks.nix
    ./parts/templates.nix

    # Library functions and host registry
    ./flake/lib.nix
    ./flake/machines/default.nix

    # Standalone home-manager configurations
    ./flake/homes/djoolz.nix
  ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
    # "aarch64-darwin"
    # "x86_64-darwin"
  ];

  flake.deploy = inputs.self.lib.deploy;

  perSystem =
    {
      inputs',
      pkgs,
      system,
      ...
    }:
    let
      deployFileTransformPath = "${inputs.deploy-rs}/nix/transform-deploy.nix";
      postDeployGc = pkgs.writeShellApplication {
        name = "post-deploy-gc";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
          pkgs.nix
          pkgs.openssh
          pkgs.python3
        ];
        text = ''
          node="''${1:?Usage: post-deploy-gc NODE HOSTNAME SSH_OPTS SSH_USER SUDO DEPLOY_FILE}"
          hostname="''${2:-}"
          ssh_opts_override="''${3:-}"
          ssh_user="''${4:-}"
          sudo_override="''${5:-}"
          deploy_file="''${6:-}"

          if [[ ! "$node" =~ ^[[:alnum:]_.-]+$ ]]; then
            printf 'Skipping post-deployment GC: invalid node name %q\n' "$node" >&2
            exit 0
          fi
          if [ -n "$deploy_file" ]; then
            deployment_data="$(nix-instantiate --strict --read-write-mode --json --eval -E \
              "((import ${deployFileTransformPath}) (let r = import ''${deploy_file}/.; in
                if builtins.isFunction r then (r {}).deploy else r.deploy))")"
            node_data="$(jq -c --arg node "$node" '.nodes[$node] // {}' <<< "$deployment_data")"
            configured_opts="$(jq -r --arg node "$node" \
              '(.nodes[$node].sshOpts // .sshOpts // []) | .[]' \
              <<< "$deployment_data" | paste -sd' ' -)"
          else
            node_data="$(nix eval --json ".#lib.deploy.nodes.\"$node\"")" || node_data="{}"
            configured_opts="$(jq -r '.sshOpts // [] | .[]' <<< "$node_data" | paste -sd' ' -)"
            if [ -z "$configured_opts" ]; then
              configured_opts="$(nix eval --json .#lib.deploy.sshOpts |
                jq -r '.[]' | paste -sd' ' -)"
            fi
          fi

          if [ -z "$hostname" ]; then
            hostname="$(jq -r '.hostname // empty' <<< "$node_data")"
            if [ -z "$hostname" ]; then
              printf 'Post-deployment GC could not resolve hostname for %s\n' "$node" >&2
              exit 0
            fi
          fi
          if [ -z "$ssh_user" ]; then
            ssh_user="$(jq -r '.sshUser // empty' <<< "$node_data")"
          fi
          if [ -z "$sudo_override" ]; then
            sudo_override="$(jq -r '.sudo // empty' <<< "$node_data")"
          fi

          if [ -n "$ssh_opts_override" ]; then
            read -r -a ssh_opts <<< "$ssh_opts_override"
          elif [ -n "$configured_opts" ]; then
            read -r -a ssh_opts <<< "$configured_opts"
          else
            ssh_opts=()
          fi

          if [ -z "$ssh_user" ]; then
            ssh_user="$(whoami)"
          fi

          target="$ssh_user@$hostname"

          remote_command=()
          if [ -n "$sudo_override" ]; then
            mapfile -d $'\0' -t remote_command < <(python3 -c \
              'import shlex,sys; print("\0".join(shlex.split(sys.argv[1])), end="\0")' \
              "$sudo_override")
            remote_command+=(-u root)
          elif [ "$ssh_user" != "root" ]; then
            remote_command=(sudo -u root)
          fi
          remote_command+=(nix-collect-garbage --delete-older-than 30d)

          printf -v quoted_command '%q ' "''${remote_command[@]}"
          # shellcheck disable=SC2029
          if ! ssh "''${ssh_opts[@]}" "$target" "$quoted_command"; then
            printf 'Post-deployment GC failed on %s; deployment remains successful\n' "$node" >&2
          fi
        '';
      };
    in
    {
      checks = inputs.deploy-rs.lib.${system}.deployChecks inputs.self.lib.deploy;

      packages = {
        post-deploy-gc = postDeployGc;
        # activation safety and unsuitable for deploying a focused host.
        deploy-rs = pkgs.writeShellApplication {
          name = "deploy";
          runtimeInputs = [
            inputs'.deploy-rs.packages.default
            pkgs.coreutils
            pkgs.nix
            pkgs.jq
            pkgs.python3
            postDeployGc
          ];
          text = ''
            log_file="$(mktemp)"
            trap 'rm -f "$log_file"' EXIT
            hostname_override=""
            ssh_opts_override=""
            ssh_user_override=""
            sudo_override=""
            deploy_file=""
            skip_gc=false
            take_value=""

            for arg in "$@"; do
              if [ -n "$take_value" ]; then
                case "$take_value" in
                  hostname) hostname_override="$arg" ;;
                  ssh-opts) ssh_opts_override="$arg" ;;
                  ssh-user) ssh_user_override="$arg" ;;
                  sudo) sudo_override="$arg" ;;
                  file) deploy_file="$arg" ;;
                esac
                take_value=""
                continue
              fi

              case "$arg" in
                --hostname) take_value=hostname ;;
                --hostname=*) hostname_override="''${arg#--hostname=}" ;;
                --ssh-opts) take_value=ssh-opts ;;
                --ssh-opts=*) ssh_opts_override="''${arg#--ssh-opts=}" ;;
                --ssh-user) take_value=ssh-user ;;
                --ssh-user=*) ssh_user_override="''${arg#--ssh-user=}" ;;
                --sudo) take_value=sudo ;;
                --sudo=*) sudo_override="''${arg#--sudo=}" ;;
                --file|-f) take_value="file" ;;
                --file=*) deploy_file="''${arg#--file=}" ;;
                --dry-activate|--boot) skip_gc=true ;;
              esac
            done

            # Keep this as one deploy-rs invocation: it owns multi-target rollback.
            if deploy --skip-checks --no-progress "$@" 2>&1 | tee "$log_file"; then
              deploy_status=0
            else
              deploy_status="''${PIPESTATUS[0]}"
            fi

            python3 - "$log_file" "$deploy_status" "$skip_gc" "$hostname_override" \
              "$ssh_opts_override" "$ssh_user_override" "$sudo_override" "$deploy_file" <<'PY'
            import re
            import subprocess
            import sys

            log_path, status, skip_gc, hostname, ssh_opts, ssh_user, sudo, deploy_file = sys.argv[1:]
            status = int(status)
            if skip_gc == "true":
                sys.exit(status)

            expected = {}
            confirmed = {}
            active_profile = None
            rollback_started = False
            patterns = (
                re.compile(r"starting build of profile (\S+) on node (\S+)"),
                re.compile(r"Building profile `([^`]+)` for node `([^`]+)`"),
            )
            activation = re.compile(r"Activating profile `([^`]+)` for node `([^`]+)`")

            with open(log_path, encoding="utf-8", errors="replace") as log:
                for line in log:
                    if "Revoking previous deploys" in line:
                        rollback_started = True
                    match = None
                    for pattern in patterns:
                        match = pattern.search(line)
                        if match:
                            break
                    if match:
                        expected.setdefault(match.group(2), set()).add(match.group(1))
                    match = activation.search(line)
                    if match:
                        active_profile = (match.group(2), match.group(1))
                    if active_profile and "Deployment confirmed." in line:
                        confirmed.setdefault(active_profile[0], set()).add(active_profile[1])
                        active_profile = None

            if rollback_started:
                sys.exit(status)

            candidates = sorted(node for node, profiles in expected.items()
                                if profiles and profiles <= confirmed.get(node, set()))
            for node in candidates:
                command = ["post-deploy-gc", node, hostname, ssh_opts, ssh_user, sudo, deploy_file]
                subprocess.run(command, check=False)
            sys.exit(status)
            PY
          '';
        };
        deploy-fleet = pkgs.writeShellApplication {
          name = "deploy-fleet";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.jq
            pkgs.nix
            pkgs.python3
            postDeployGc
            inputs'.deploy-rs.packages.default
          ];
          # Each node deploys independently so an unreachable node cannot block
          # activation on the rest of the fleet.
          text = ''
            failed_nodes=()
            hostname_override=""
            ssh_opts_override=""
            ssh_user_override=""
            sudo_override=""
            deploy_file=""
            take_value=""
            skip_gc=false

            for arg in "$@"; do
              if [ -n "$take_value" ]; then
                case "$take_value" in
                  hostname) hostname_override="$arg" ;;
                  ssh-opts) ssh_opts_override="$arg" ;;
                  ssh-user) ssh_user_override="$arg" ;;
                  sudo) sudo_override="$arg" ;;
                  file) deploy_file="$arg" ;;
                esac
                take_value=""
                continue
              fi
              case "$arg" in
                --hostname) take_value=hostname ;;
                --hostname=*) hostname_override="''${arg#--hostname=}" ;;
                --ssh-opts) take_value=ssh-opts ;;
                --ssh-opts=*) ssh_opts_override="''${arg#--ssh-opts=}" ;;
                --ssh-user) take_value=ssh-user ;;
                --ssh-user=*) ssh_user_override="''${arg#--ssh-user=}" ;;
                --sudo) take_value=sudo ;;
                --sudo=*) sudo_override="''${arg#--sudo=}" ;;
                --file|-f) take_value="file" ;;
                --file=*) deploy_file="''${arg#--file=}" ;;
                --dry-activate|--boot) skip_gc=true ;;
              esac
            done

            if [ -n "$deploy_file" ]; then
              nodes="$(nix-instantiate --strict --read-write-mode --json --eval -E \
                "((import ${deployFileTransformPath}) (let r = import ''${deploy_file}/.; in
                  if builtins.isFunction r then (r {}).deploy else r.deploy))" | jq -r '.nodes | keys[]')"
            else
              nodes="$(nix eval --raw .#lib.deploy --apply \
                'deploy: builtins.concatStringsSep " " (builtins.attrNames deploy.nodes)')"
            fi
            local_host="$(hostname --short)"
            failed_nodes=()

            for node in $nodes; do
              if [ "$node" = "$local_host" ]; then
                printf 'Skipping %s: cannot activate this host through its own Tailscale address\n' "$node"
                continue
              fi

              log_file="$(mktemp)"
              if deploy --skip-checks --rollback-succeeded false "$@" ".#''${node}" 2>&1 |
                tee "$log_file"; then
                deploy_status=0
              else
                deploy_status="''${PIPESTATUS[0]}"
              fi

              if python3 - "$log_file" "$node" <<'PY'
            import re
            import sys

            log_path, node = sys.argv[1:]
            expected = set()
            confirmed = set()
            active_profile = None
            rollback_started = False
            patterns = (
                re.compile(r"starting build of profile (\S+) on node (\S+)"),
                re.compile(r"Building profile `([^`]+)` for node `([^`]+)`"),
            )
            activation = re.compile(r"Activating profile `([^`]+)` for node `([^`]+)`")
            with open(log_path, encoding="utf-8", errors="replace") as log:
                for line in log:
                    if "Revoking previous deploys" in line:
                        rollback_started = True
                    match = None
                    for pattern in patterns:
                        match = pattern.search(line)
                        if match:
                            break
                    if match and match.group(2) == node:
                        expected.add(match.group(1))
                    match = activation.search(line)
                    if match and match.group(2) == node:
                        active_profile = match.group(1)
                    if active_profile and "Deployment confirmed." in line:
                        confirmed.add(active_profile)
                        active_profile = None
            sys.exit(0 if expected and expected <= confirmed and not rollback_started else 1)
            PY
              then
                printf 'Activated %s\n' "$node"
                if [ "$skip_gc" = false ]; then
                  if ! post-deploy-gc "$node" "$hostname_override" "$ssh_opts_override" \
                    "$ssh_user_override" "$sudo_override" "$deploy_file"; then
                    printf 'Post-deployment GC setup failed on %s; deployment remains successful\n' "$node" >&2
                  fi
                fi
              elif [ "$deploy_status" -ne 0 ]; then
                printf 'Failed to activate %s\n' "$node" >&2
                failed_nodes+=("$node")
              fi
              rm -f "$log_file"
            done

            if [ "''${#failed_nodes[@]}" -gt 0 ]; then
              printf 'Fleet deployment failed for: %s\n' "''${failed_nodes[*]}" >&2
              exit 1
            fi
          '';
        };
        fast-flake-update = inputs'.fast-flake-update.packages.default;
        flake-fmt = inputs'.flake-fmt.packages.default;
      };
    };

  flake = {

    # `nixosConfigurations` are defined by flake/machines/default.nix,
    # which registers canonical host definitions under nixos/machines/.

    # Reusable NixOS capability modules for this or other flakes.
    nixosModules = {
      system-base = ./modules/nixos/system/base.nix;
      system-wsl = ./modules/nixos/system/wsl.nix;
      avahi-discovery = ./modules/nixos/services/avahi-discovery.nix;
      bluetooth = ./modules/nixos/services/bluetooth.nix;
      printing = ./modules/nixos/services/printing.nix;
      ssh-server = ./modules/nixos/services/ssh-server.nix;
      tailscale-client = ./modules/nixos/services/tailscale-client.nix;
      tailscale-router = ./modules/nixos/services/tailscale-router.nix;
      flatpak = ./modules/nixos/services/flatpak.nix;
      flatpak-browsers = ./modules/nixos/flatpak/browsers.nix;
      flatpak-creative = ./modules/nixos/flatpak/creative.nix;
      flatpak-development = ./modules/nixos/flatpak/development.nix;
      flatpak-media = ./modules/nixos/flatpak/media.nix;
      flatpak-messaging = ./modules/nixos/flatpak/messaging.nix;
      flatpak-productivity = ./modules/nixos/flatpak/productivity.nix;
      devenv = ./modules/nixos/system/devenv.nix;
      docker = ./modules/nixos/virtualisation/docker.nix;
      docker-rootless = ./modules/nixos/virtualisation/docker_rootless.nix;
    };

    # Home-manager configurations are defined in flake/homes/*.nix
  };
  # See flake.parts for more features, such as `perSystem`
}
