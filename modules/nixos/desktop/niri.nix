{ config, inputs, lib, pkgs, ... }: {
  # Niri Desktop Environment — Self-Contained
  # Imports shared desktop infrastructure from common.nix
  # Provides: Niri compositor + Wayland tooling + shared desktop stack

  imports = [
    ./common.nix
    inputs.noctalia.nixosModules.default
    inputs.nirinit.nixosModules.nirinit
  ];

  programs.niri.enable = true;

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
      ExecStart = lib.mkForce [
        ""
        "${
          inputs.nirinit.packages.${pkgs.stdenv.hostPlatform.system}.default
        }/bin/nirinit --config %h/.config/nirinit/config.toml"
      ];
      Restart = "always";
    };
  };

  # Authentication / secrets
  security.polkit.enable = true;
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
    # Grants write access to charge_control_end_threshold for users in the
    # 'battery_ctl' group, only for BAT0
    SUBSYSTEM=="power_supply", KERNEL=="BAT0", \
        RUN+="${pkgs.coreutils}/bin/chgrp battery_ctl /sys$devpath/charge_control_end_threshold", \
        RUN+="${pkgs.coreutils}/bin/chmod g+w /sys$devpath/charge_control_end_threshold"
  '';
  environment.systemPackages = with pkgs; [
    alacritty
    fuzzel
    polkit_gnome
    swaylock
    mako
    swayidle
    swaybg
    xwayland-satellite # XWayland support
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
