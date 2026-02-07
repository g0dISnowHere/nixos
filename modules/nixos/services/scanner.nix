{ config, pkgs, lib, ... }: {
  # Scanner Support with SANE Backend
  # Enables hardware.sane for scanner support with workaround for Canon LiDE 25
  # Automatically adds users to required groups
  # Reference: https://nixos.wiki/wiki/Scanners

  hardware.sane = {
    enable = true;

    # Workaround for Canon LiDE 25 scanner
    # https://github.com/NixOS/nixpkgs/issues/273280
    backends-package = pkgs.sane-backends.overrideAttrs (old: {
      configureFlags = (old.configureFlags or [ ]) ++ [
        # Disable locking to work around Canon LiDE 25 issues
        # Better solution would be to configure proper lock directory:
        # "--localstatedir=/var"
        # "--with-lockdir=/var/lock/sane"
        # But this requires additional setup. For now, disable locking.
        "--disable-locking"
      ];
    });
  };

  # Scanner packages
  environment.systemPackages = with pkgs;
    [
      xsane # GUI for scanning
      # sane-backends # CLI for scanning (already included via hardware.sane)
    ];

  # Note: Add 'scanner' and 'lp' to user's extraGroups in machine config:
  # users.users.djoolz.extraGroups = [ ... "scanner" "lp" ];
}

