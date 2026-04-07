{ config, pkgs, ... }: {
  # KDE Plasma Desktop Environment — Self-Contained
  # Imports shared desktop infrastructure from common.nix
  # Provides: Plasma 6 DE + SDDM, plus all dependencies from common.nix
  # Reference: https://wiki.nixos.org/wiki/KDE

  imports = [ ./common.nix ];

  # Enable Plasma 6 Desktop Environment
  services.desktopManager.plasma6.enable = true;

  # Enable SDDM display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Standardize on GNOME Keyring as the Secret Service backend so Plasma does
  # not depend on KWallet for Wi-Fi and other desktop secrets.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  security.pam.services.login.kwallet.enable = false;
  security.pam.services.sddm.kwallet.enable = false;
}
