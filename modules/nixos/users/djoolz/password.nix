{ config, ... }: {
  sops.secrets."djoolz-password" = {
    sopsFile = ../../../../secrets/users/djoolz/password.yaml;
    format = "yaml";
    key = "passwordHash";
    neededForUsers = true;
    owner = "root";
    mode = "0400";
  };

  users.users.djoolz.hashedPasswordFile =
    config.sops.secrets."djoolz-password".path;
}
