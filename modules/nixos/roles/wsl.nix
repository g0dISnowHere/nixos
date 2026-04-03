{ ... }: {
  imports = [
    ../system/ai-tools.nix
    ../system/locale.nix
    ../system/login-shell.nix
    ../system/services.nix
    ../services/ssh.nix
    ../services/tailscale.nix
  ];

  my.tailscale.enableSSH = true;
  # NixOS-WSL configuration for frictionless experience
  wsl = {
    enable = true;
    useWindowsDriver = true; # Enable GPU passthrough (including NVIDIA)
    docker-desktop.enable =
      true; # Enable Docker Desktop integration for containers
    interop = {
      includePath = true;
      register = true; # Allow running Windows executables
    };
    ssh-agent.enable = true; # SSH agent passthrough
    startMenuLaunchers = true; # GUI app shortcuts in Windows start menu
    wslConf = {
      automount.enabled = true; # Mount Windows drives
      interop.enabled = true; # Enable interop
      interop.appendWindowsPath = true; # Include Windows PATH
      boot.systemd = true; # Use systemd as init
    };
  };
}
