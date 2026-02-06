# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ../../../modules/nixos/system/autoupgrade.nix
    ../../../modules/nixos/desktop/gnome.nix
    # ./homeassistant.nix
    ../../../modules/nixos/system/locale.nix
    ./other-hardware.nix
    ../../../modules/nixos/system/services.nix
    # ./ssh.nix
    ../../../modules/nixos/system/shell.nix
    ../../../modules/nixos/services/tailscale.nix
    # ../../../modules/nixos/virtualisation/docker.nix
    ../../../modules/nixos/virtualisation/docker_rootless.nix
    # ../../../modules/nixos/virtualisation/quickemu.nix
    # ../../../modules/nixos/virtualisation/libvirtd.nix
    # ../../../modules/nixos/virtualisation/podman.nix
  ];

  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      # lockAll = true; # prevents overriding
      settings = {
        "org/gnome/desktop/interface" = {
          # clock-show-weekday = true;
        };
      };
    }];
  };

  # https://nixos.wiki/wiki/Appimage
  programs = {
    appimage = {
      enable = true;
      binfmt = true;
      package = pkgs.appimage-run.override {
        # extraPkgs = pkgs:
        #   [

        #     pkgs.python312

        #   ];
      };

    };
    # https://nix.dev/permalink/stub-ld
    nix-ld = {
      enable = true;
      libraries = with pkgs;
        [
          # Add any missing dynamic libraries for unpackaged programs
          # here, NOT in environment.systemPackages
          stdenv.cc.cc # for basic-memory mcp
        ];
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  security.pki.certificates = [ ]; # freecad seems to need this

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.djoolz = {
    isNormalUser = true;
    description = "djoolz";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "wireshark"
      "libvirtd"
      "plugdev" # for logitech mouse (unifying receiver, piper, solaar, etc.)
    ];
    packages = with pkgs;
      [
        #  thunderbird
      ];
  };
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    dbus
    intel-gpu-tools
    intel-undervolt
    inteltool
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
