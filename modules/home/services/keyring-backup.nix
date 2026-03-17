{ pkgs, ... }: {
  # Keep recent point-in-time backups of the login keyring so a bad session
  # transition does not permanently strand browser secrets behind a newly
  # created keyring.
  systemd.user.services.keyring-backup = {
    Unit.Description = "Backup the login keyring";

    Service = {
      Type = "oneshot";
      ExecStart = let
        backupScript = pkgs.writeShellScript "keyring-backup" ''
          set -eu

          keyring="$HOME/.local/share/keyrings/login.keyring"
          backup_dir="$HOME/.local/share/keyrings/backups"
          latest_link="$backup_dir/login.keyring.latest"

          if [ ! -f "$keyring" ]; then
            exit 0
          fi

          mkdir -p "$backup_dir"

          if [ -L "$latest_link" ]; then
            latest_target="$(readlink -f "$latest_link")"
            if [ -n "$latest_target" ] && [ -f "$latest_target" ] && cmp -s "$keyring" "$latest_target"; then
              exit 0
            fi
          fi

          timestamp="$(date +%Y%m%d-%H%M%S-%N)"
          destination="$backup_dir/login.keyring.$timestamp"

          install -m 600 "$keyring" "$destination"
          ln -sfn "$(basename "$destination")" "$latest_link"

          find "$backup_dir" -maxdepth 1 -type f -name 'login.keyring.*' -printf '%f\n' \
            | sort -r \
            | tail -n +11 \
            | while IFS= read -r old_backup; do
                rm -f "$backup_dir/$old_backup"
              done
        '';
      in "${backupScript}";
    };

    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.paths.keyring-backup = {
    Unit.Description = "Watch the login keyring for changes";

    Path = {
      PathExists = "%h/.local/share/keyrings/login.keyring";
      PathChanged = "%h/.local/share/keyrings/login.keyring";
    };

    Install.WantedBy = [ "default.target" ];
  };
}
