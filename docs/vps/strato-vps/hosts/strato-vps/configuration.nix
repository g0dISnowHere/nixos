{ lib, pkgs, ... }: {
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking = {
    hostName = "strato-vps";

    # Current host uses DHCP on ens6 for both IPv4 and IPv6.
    useDHCP = lib.mkDefault false;
    interfaces.ens6.useDHCP = lib.mkDefault true;
    enableIPv6 = true;
  };

  time.timeZone = "Etc/UTC";

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    efiSupport = false;
  };

  services.resolved.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItFDRkSHQOn8MlPIjHx/kSPDYSpElw+SozdUIjMMDGe djoolz@mirach"
  ];

  environment.systemPackages = with pkgs; [
    git
    curl
    htop
    tmux
    vim
  ];

  # Do not change casually. See ../../../architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
