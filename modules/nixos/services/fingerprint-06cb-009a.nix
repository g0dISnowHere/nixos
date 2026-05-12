{ inputs, pkgs, ... }:
let
  fpSrc = inputs.nixos-06cb-009a-fingerprint-sensor.outPath;
  pythonValidity =
    pkgs.callPackage ./fingerprint-06cb-009a-python-validity.nix {
      inherit fpSrc;
    };
  gdmPam = "${pkgs.gdm}/lib/security/pam_gdm.so";
  gnomeKeyringPam = "${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so";
in {
  # Synaptics Metallica MIS Touch Fingerprint Reader
  # USB ID: 06cb:009a
  #
  # Upstream libfprint/fprintd does not support this device directly.
  # Keep using open-fprintd + python-validity, but patch python-validity for
  # current nixpkgs Python packaging.

  environment.systemPackages = [ pkgs.fprintd pythonValidity ];

  systemd = {
    packages = [ pkgs.open-fprintd pythonValidity ];

    services = {
      python3-validity = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
        };
      };
      open-fprintd-resume.wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
      open-fprintd-suspend.wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
    };
  };

  # Register D-Bus service files from both packages.
  services.dbus.packages = [ pkgs.open-fprintd pythonValidity ];

  # open-fprintd replaces upstream fprintd daemon, but keep fprintd CLI tools.
  services.fprintd.enable = false;

  security.pam.services = {
    login.fprintAuth = true;
    sudo.fprintAuth = true;
    swaylock.fprintAuth = true;
    polkit-1.fprintAuth = true;

    # NixOS only generates this service automatically when
    # `services.fprintd.enable = true`. With open-fprintd we still need the
    # PAM service so GDM can offer fingerprint auth at login.
    gdm-fingerprint.text = ''
      auth       required                    pam_shells.so
      auth       requisite                   pam_nologin.so
      auth       requisite                   pam_faillock.so      preauth
      auth       required                    ${pkgs.fprintd}/lib/security/pam_fprintd.so
      auth       required                    pam_env.so conffile=/etc/pam/environment readenv=0
      auth       [success=ok default=1]      ${gdmPam}
      auth       optional                    ${gnomeKeyringPam}

      account    include                     login

      password   required                    pam_deny.so

      session    include                     login
    '';
  };
}
