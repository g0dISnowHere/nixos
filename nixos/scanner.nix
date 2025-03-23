{ pkgs, ... }:
{
  # https://nixos.wiki/wiki/Scanners
  hardware.sane = {
    enable = true;

    ## Workaround for Canon LiDE 25.
    # https://github.com/NixOS/nixpkgs/issues/273280
    backends-package = pkgs.sane-backends.overrideAttrs (old: {
      configureFlags = (old.configureFlags or []) ++ [
        # "--localstatedir=/var" # `sane-backends` puts e.g. lock files in here, must not be in /nix/store
        # "--with-lockdir=/var/lock/sane" # `sane-backends` puts e.g. lock files in here, must not be in /nix/store

        # Ugly workaround for https://github.com/NixOS/nixpkgs/issues/273280#issuecomment-1848873028
        # Really we should make `sane-backends` be able to provide a real lock dir (e.g. `/var/lock/sane`).
        "--disable-locking"
      ];
      # Alternative workaround for https://github.com/NixOS/nixpkgs/issues/273280#issuecomment-1848873028
      # We'd prefer to just set in `configureFlags`
      #     "--localstatedir=/var" # `sane-backends` puts e.g. lock files in here, must not be in /nix/store
      # but that does not work because the install step tries to create this directory,
      # which fails in the nix build sandbox.
      # So instead, we set the preprocessor variable directly, see:
      #     https://gitlab.com/sane-project/backends/-/blob/65779d6b595547d155a1954958bce5faaad45a5d/configure.ac#L635-652
      # A problem is that this lock dir also needs to exist and have write permissions.
      # Right now you have to do that manually with:
      #     sudo mkdir -p /var/lock/sane && sudo chown root:scanner /var/lock/sane && sudo chmod g+w /var/lock/sane
      # Maybe we should use the `scanner` group for that, and/or configure it with systemd `tmpfiles`.
      #NIX_CFLAGS_COMPILE = "-DPATH_SANE_LOCK_DIR=/var/lock/sane";
      });
  };

  ## also added user to groupps "scanners" and "lp"
  users.users.djoolz.extraGroups = [ "scanner" "lp" ]; # make sure this works with home-manager!

  # ## This part doesn't work... It should enable the scanner in GIMP: File->Create->XSane
  # nixpkgs.config.packageOverrides = pkgs: {
  #   xsaneGimp = pkgs.xsane.override { gimpSupport = true; };
  # };
}