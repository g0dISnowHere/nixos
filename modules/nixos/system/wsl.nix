_: {
  # NixOS-WSL platform configuration for Windows-hosted environments.
  wsl = {
    enable = true;
    useWindowsDriver = true;
    docker-desktop.enable = true;
    interop = {
      includePath = true;
      # WSL owns the protected binfmt registry; reuse its Windows handler.
      register = false;
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
