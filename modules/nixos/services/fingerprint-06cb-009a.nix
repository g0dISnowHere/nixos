{ inputs, pkgs, ... }:
let
  fpSrc = inputs.nixos-06cb-009a-fingerprint-sensor.outPath;
  pythonValidity = pkgs.callPackage ./fingerprint-06cb-009a-python-validity.nix {
    inherit fpSrc;
  };
  gdmPam = "${pkgs.gdm}/lib/security/pam_gdm.so";
  gnomeKeyringPam = "${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so";
in
{
  # Synaptics Metallica MIS Touch Fingerprint Reader
  # USB ID: 06cb:009a
  #
  # Upstream libfprint/fprintd does not support this device directly.
  # Keep using open-fprintd + python-validity, but patch python-validity for
  # current nixpkgs Python packaging.

  environment.systemPackages = [
    pkgs.fprintd
    pythonValidity
  ];

  systemd = {
    packages = [
      pkgs.open-fprintd
      pythonValidity
    ];

    services = {
      python3-validity = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Restart = "always";
          RestartSec = "1s";
          StartLimitIntervalSec = 0;
        };
      };

      python3-validity-suspend = {
        description = "Stop python3-validity before system sleep";
        before = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
          "systemd-hybrid-sleep.service"
          "systemd-suspend-then-hibernate.service"
        ];
        wantedBy = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
          "suspend-then-hibernate.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl stop python3-validity.service";
        };
      };

      open-fprintd-resume = {
        wantedBy = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
          "suspend-then-hibernate.target"
        ];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "2s";
          StartLimitIntervalSec = 60;
          StartLimitBurst = 5;
        };
      };

      python3-validity-resume = {
        description = "Restart python3-validity after fingerprint resume";
        after = [ "open-fprintd-resume.service" ];
        wantedBy = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
          "suspend-then-hibernate.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl restart python3-validity.service";
        };
      };

      open-fprintd-suspend.wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
    };
  };

  services = {
    udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="009a", TEST=="power/control", ATTR{power/control}="on"
    '';

    # Register D-Bus service files from both packages.
    dbus.packages = [
      pkgs.open-fprintd
      pythonValidity
    ];

    # open-fprintd replaces upstream fprintd daemon, but keep fprintd CLI tools.
    fprintd.enable = false;

  };
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
