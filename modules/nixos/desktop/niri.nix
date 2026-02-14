{ config, pkgs, ... }: {
  # Niri Desktop Environment — Self-Contained
  # Imports shared desktop infrastructure from common.nix
  # Provides: Niri compositor + Wayland tooling + shared desktop stack

  imports = [ ./common.nix ];

  programs.niri.enable = true;

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

  # Wayland utilities
  programs.waybar.enable = true; # Top bar
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
