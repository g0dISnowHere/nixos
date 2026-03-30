{ lib, pkgs, ... }: {
  imports = [ ./disko.nix ./hardware-configuration.nix ];

  networking.hostName = "strato-vps";

  time.timeZone = "Etc/UTC";

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    efiSupport = false;
  };

  # Current host uses DHCP on ens6 for both IPv4 and IPv6.
  networking.useDHCP = lib.mkDefault false;
  networking.interfaces.ens6.useDHCP = lib.mkDefault true;
  networking.enableIPv6 = true;

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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3xT7vBshGEBHXaKNaneuJlbtXWrvJp/bQjxnOFvH+G coolify"
  ];

  environment.systemPackages = with pkgs; [ git curl htop tmux vim ];

  # Do not change casually. See ../../../architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
