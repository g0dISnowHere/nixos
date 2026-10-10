{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./firewall.nix
    inputs.nixos-wsl.nixosModules.default
    ../../../modules/nixos/system/base.nix
    ../../../modules/nixos/system/home-manager.nix
    ../../../modules/nixos/system/ai-tools.nix
    ../../../modules/nixos/system/developer-tools.nix
    ../../../modules/nixos/system/wsl.nix
    ../../../modules/nixos/services/monitoring-baseline.nix
    ../../../modules/nixos/services/monitoring-alloy.nix
    ../../../modules/nixos/services/vscode-remote.nix
    ../../../modules/nixos/services/ssh-server.nix
    ../../../modules/nixos/services/tailscale-base.nix
    ../../../modules/nixos/services/tailscale-ssh.nix
    ../../../modules/nixos/virtualisation/docker.nix
  ];

  networking.hostName = hostname;

  # Leave room for Tailscale encapsulation; the Windows WSL link uses MTU 1500.
  networking.interfaces.eth0.mtu = 1500;

  # WSL creates eth0 before NixOS starts; its MTU is not reapplied by the .link rule.
  systemd.services.wsl-eth0-mtu = {
    description = "Apply the WSL underlay MTU before Tailscale starts";
    wantedBy = [ "multi-user.target" ];
    requires = [ "sys-subsystem-net-devices-eth0.device" ];
    after = [ "sys-subsystem-net-devices-eth0.device" ];
    before = [
      "network-pre.target"
      "tailscaled.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip link set dev eth0 mtu ${toString config.networking.interfaces.eth0.mtu}";
    };
  };

  # WSL can restore eth0's MTU to 1280 after resume. Reassert 1500 on only
  # MTU-change notifications; this never takes the interface down.
  systemd.services.alhena-eth0-mtu = {
    description = "Restore Alhena WSL ethernet MTU after host reset";
    wantedBy = [ "multi-user.target" ];
    path = [
      pkgs.coreutils
      pkgs.iproute2
    ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "1s";
    };
    script = ''
      ip monitor link dev eth0 | while IFS= read -r _; do
        mtu="$(cat /sys/class/net/eth0/mtu)"
        if [ "$mtu" != 1500 ]; then
          ip link set dev eth0 mtu 1500
        fi
      done
      echo "eth0 link monitor stopped" >&2
      exit 1
    '';
  };

  wsl = {
    enable = true;
    defaultUser = "djoolz";
    startMenuLaunchers = true;
  };

  # WSL exposes audit kernel support, but auditd cannot register its daemon PID.
  security.audit.enable = lib.mkForce false;
  security.auditd.enable = lib.mkForce false;
  services.journald.audit = lib.mkForce false;

  # Hardware configuration for NVIDIA GPU support in containers
  hardware.nvidia-container-toolkit = {
    enable = true;
    suppressNvidiaDriverAssertion = true; # Suppress assertion since NVIDIA driver is provided by WSL/Windows host
  };

  users.users.djoolz.extraGroups = [ "wheel" ];

  # Home Manager configuration for this machine.
  home-manager.users.djoolz = {
    imports = [ ../../../flake/homes/users/djoolz/base.nix ];
    # Do not change casually. See docs/architecture/state-version-reasons.md.
    home.stateVersion = "25.11";
  };

  my.monitoring = {
    enable = true;
    site = "home";
  };

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = lib.mkDefault "25.11";
}
