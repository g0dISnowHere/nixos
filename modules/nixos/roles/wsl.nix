{ ... }: {
  imports = [
    ../system/locale.nix
    ../system/login-shell.nix
    ../system/services.nix
    ../services/ssh.nix
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}