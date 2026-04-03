{ lib, hostname, pkgs, ... }: {
  # STRATO VPS
  # Remote x86_64 server currently documented under vps docs/
  # Role: headless VPS with SSH, Tailscale, and container workloads

  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/system/autoupgrade.nix
  ];

  networking.hostName = hostname;
  time.timeZone = lib.mkForce "Etc/UTC";

  # The shared homelab role assumes NetworkManager. This VPS should stay on
  # provider-style networkd + DHCP for remote reliability.
  networking.networkmanager.enable = false;
  networking.useDHCP = lib.mkDefault false;
  networking.enableIPv6 = true;

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;
    networks."10-ens6" = {
      matchConfig.Name = "ens6";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  services.resolved.enable = true;

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 8 * 1024;
  }];

  # Keep serial console access aligned with the audited host.
  boot.kernelParams = [ "console=tty1" "console=ttyS0" ];

  services.openssh.settings = {
    PermitRootLogin = lib.mkForce "prohibit-password";
    PasswordAuthentication = lib.mkForce false;
    KbdInteractiveAuthentication = false;
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItFDRkSHQOn8MlPIjHx/kSPDYSpElw+SozdUIjMMDGe djoolz@mirach"
  ];

  users.users.djoolz = {
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItFDRkSHQOn8MlPIjHx/kSPDYSpElw+SozdUIjMMDGe djoolz@mirach"
    ];
  };

  environment.systemPackages = with pkgs; [ curl git htop tmux vim ];

  my.autoUpdate = {
    enable = true;
    mode = "updater";
    onCalendar = "weekly";
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
