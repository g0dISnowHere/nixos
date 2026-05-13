{ lib, hostname, pkgs, ... }: {
  # STRATO VPS
  # Remote x86_64 server currently documented under vps docs/
  # Role: headless VPS with SSH, Tailscale, and container workloads

  imports = [
    ./hardware-configuration.nix
    ./docker-compose-secrets.nix
    ../../../modules/nixos/system/autoupgrade.nix
  ];

  networking = {
    hostName = hostname;
    firewall.enable = true;

    # This VPS should stay on provider-style networkd + DHCP for remote
    # reliability.
    networkmanager.enable = false;
    useDHCP = lib.mkDefault false;
    enableIPv6 = true;
  };
  systemd = {
    network = {
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

    services."getty@tty1".enable = true;
    services."serial-getty@ttyS0".enable = true;
  };

  services.resolved.enable = true;

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    extraConfig = ''
      serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
      terminal_input console serial
      terminal_output console serial
    '';
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 8 * 1024;
  }];

  # Keep provider recovery consoles usable through both boot and login.
  boot.kernelParams = [ "console=tty1" "console=ttyS0" "systemd.ssh_auto=no" ];

  users.users.djoolz = { extraGroups = [ "wheel" ]; };

  environment.systemPackages = with pkgs; [ curl git htop tmux vim ];

  my.autoUpdate = {
    enable = true;
    mode = "updater";
    onCalendar = "weekly";
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
