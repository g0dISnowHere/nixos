{ ... }: {
  imports = [ ./password.nix ];

  users.users.djoolz = {
    isNormalUser = true;
    description = "djoolz";
  };
}
