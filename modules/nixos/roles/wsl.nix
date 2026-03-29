{ ... }: {
  imports = [
    ../system/locale.nix
    ../system/login-shell.nix
    ../system/services.nix
    ../services/ssh.nix
    ../services/tailscale.nix
  ];

  my.tailscale.enableSSH = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
