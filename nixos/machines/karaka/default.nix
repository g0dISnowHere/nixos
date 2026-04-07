{ hostname, ... }: {
  # Karaka - Workstation migrated from the standalone karaka branch
  # Hardware: Intel system with EFI boot and swap-backed resume
  # Role: Workstation

  imports = [ ./hardware-configuration.nix ];

  networking.hostName = hostname;

  # Preserve the laptop's EFI boot and resume setup from the old karaka branch.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    resumeDevice = "/dev/disk/by-label/swap";
  };

  users.users.djoolz.extraGroups = [ "networkmanager" "wheel" "scanner" "lp" ];

  home-manager.users.djoolz = {
    imports = [ ../../../flake/homes/users/djoolz/karaka.nix ];
    # Preserve the old karaka Home Manager compatibility marker.
    home.stateVersion = "24.05";
  };

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "24.11";
}
