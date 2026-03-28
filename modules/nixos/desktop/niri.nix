{ config, inputs, lib, pkgs, ... }:
let
  niriLockScript = "%h/.config/niri/swaylock-noctalia.sh";
  fallbackLockCommand = "${pkgs.swaylock}/bin/swaylock -f";
  lockCommand = ''
    ${pkgs.bash}/bin/bash -lc 'if [ -x "${niriLockScript}" ]; then exec "${niriLockScript}"; else exec ${fallbackLockCommand}; fi'
  '';
in {
  # Niri Desktop Environment — Self-Contained
  # Imports shared desktop infrastructure from common.nix
  # Provides: Niri compositor + Wayland tooling + shared desktop stack

  imports = [
    ./common.nix
    inputs.noctalia.nixosModules.default
    inputs.nirinit.nixosModules.nirinit
  ];

  programs.niri.enable = true;

  services.udisks2.enable = true;
  services.gvfs.enable = true;

  services.noctalia-shell = {
    enable = true;
    target = "niri.service";
  };

  services.nirinit.enable = true;

  systemd.user.services.nirinit = {
    description = lib.mkForce "Nirinit";
    partOf = lib.mkForce [ "niri.service" ];
    after = lib.mkForce [ "niri.service" ];
    wantedBy = lib.mkForce [ "niri.service" ];
    serviceConfig = {
      Environment = [
        "PATH=%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin:/var/lib/flatpak/exports/bin:%h/.local/share/flatpak/exports/bin"
      ];
      ExecStart = lib.mkForce [
        ""
        "${
          inputs.nirinit.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/bin/nirinit --save-interval 30 --config %h/.config/nirinit/config.toml"
      ];
      Restart = "always";
    };
  };

  systemd.user.services.udiskie = {
    description = "Udiskie automount";
    wantedBy = [ "niri.service" ];
    after = [ "niri.service" "graphical-session.target" "dbus.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --no-tray";
      Restart = "on-failure";
    };
  };

  systemd.user.services.swayidle = {
    description = "Swayidle";
    partOf = [ "niri.service" ];
    wantedBy = [ "niri.service" ];
    after = [ "niri.service" ];
    serviceConfig = {
      Environment = [
        "PATH=%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin:/var/lib/flatpak/exports/bin:%h/.local/share/flatpak/exports/bin"
      ];
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w "
        + "timeout 300 '${lockCommand}' "
        + "timeout 330 '${pkgs.wlopm}/bin/wlopm --off' "
        + "resume '${pkgs.wlopm}/bin/wlopm --on' "
        + "timeout 1800 '${pkgs.systemd}/bin/systemctl suspend' "
        + "before-sleep '${lockCommand}' " + "lock '${lockCommand}'";
      Restart = "on-failure";
    };
  };

  # Authentication / secrets
  services.gnome.gnome-keyring.enable = true; # Secret Service
  security.pam.services.swaylock = { };
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.gdm-password.enableGnomeKeyring = true;

  # Greeter
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Portals for file pickers/screen sharing on Wayland
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Power profiles + battery info for control center widgets
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Wayland utilities
  programs.waybar.enable = false; # Top bar
  # systemd.user.services.waybar = {
  #   description = lib.mkForce "Waybar status bar";
  #   partOf = lib.mkForce [ "niri.service" ];
  #   after = lib.mkForce [ "niri.service" ];
  #   wantedBy = lib.mkForce [ "niri.service" ];
  #   serviceConfig = {
  #     ExecStart = lib.mkForce [ "" "${pkgs.waybar}/bin/waybar" ];
  #     Restart = "on-failure";
  #   };
  # };

  systemd.user.services.mako = {
    description = "Mako notification daemon";
    partOf = [ "niri.service" ];
    after = [ "niri.service" ];
    wantedBy = [ "niri.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.mako}/bin/mako -c %h/.config/mako/config";
      Restart = "on-failure";
    };
  };

  # Battery threshold control (Noctalia plugin)
  users.groups.battery_ctl = { };
  users.users.djoolz.extraGroups = [ "battery_ctl" ];
  services.udev.extraRules = ''
    # Battery Threshold Control - udev rule
    # Grants write access to any battery threshold sysfs node for users in the
    # 'battery_ctl' group.
    SUBSYSTEM=="power_supply", KERNEL=="BAT*", TEST=="charge_control_end_threshold", \
        RUN+="${pkgs.coreutils}/bin/chgrp battery_ctl /sys$devpath/charge_control_end_threshold", \
        RUN+="${pkgs.coreutils}/bin/chmod g+w /sys$devpath/charge_control_end_threshold"
  '';
  environment.systemPackages = with pkgs; [
    alacritty
    brightnessctl
    fuzzel
    mako
    # Keep an external polkit agent until the active Noctalia/Quickshell build
    # exposes Quickshell.Services.Polkit.
    polkit_gnome
    playerctl
    jq
    seahorse
    udiskie
    wlopm
    swaylock
    swayidle
    swaybg
    xwayland-satellite # XWayland support
    # Nirinit saves a per-window launch_command from the Niri window identity it
    # sees in IPC. In practice this matches app_id here, which is not always an
    # executable on PATH, so provide stable compatibility shims for restore.
    (writeShellScriptBin "Vivaldi-flatpak" ''
      exec com.vivaldi.Vivaldi "$@"
    '')
    (writeShellScriptBin "org.gnome.Nautilus" ''
      exec nautilus "$@"
    '')
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
