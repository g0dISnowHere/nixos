{ ... }: {
  imports = [
    ../system/base.nix
    ../services/ssh-server.nix
    ../services/tailscale-client.nix
  ];

  my.tailscale.enableSSH = true;

  # NixOS-WSL configuration for server-like use under Windows.
  wsl = {
    enable = true;
    useWindowsDriver = true;
    docker-desktop.enable = true;
    interop = {
      includePath = true;
      register = true;
    };
    ssh-agent.enable = true;
    startMenuLaunchers = true;
    wslConf = {
      automount.enabled = true;
      interop.enabled = true;
      interop.appendWindowsPath = true;
      boot.systemd = true;
    };
  };
}
