{
  inputs,
  pkgs,
  dotfilesRoot,
  repoRoot,
  pkgs-unstable,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
    extraSpecialArgs = {
      inherit
        dotfilesRoot
        inputs
        repoRoot
        pkgs-unstable
        ;
      isNixosIntegrated = true;
    };
    backupCommand = pkgs.writeShellScript "home-manager-backup" ''
      set -eu

      target_path="$1"
      backup_root="$HOME/.local/state/home-manager-backups"
      timestamp="$(date +%Y%m%d-%H%M%S-%N)"

      case "$target_path" in
        "$HOME"/*)
          relative_path="''${target_path#$HOME/}"
          ;;
        *)
          relative_path="external/$(basename "$target_path")"
          ;;
      esac

      backup_dir="$backup_root/$(dirname "$relative_path")"
      backup_name="$(basename "$target_path").$timestamp"
      backup_path="$backup_dir/$backup_name"

      mkdir -p "$backup_dir"
      mv "$target_path" "$backup_path"

      find "$backup_root" -type f -mtime +30 -delete
      find "$backup_root" -depth -type d -empty -delete
    '';
  };
}
