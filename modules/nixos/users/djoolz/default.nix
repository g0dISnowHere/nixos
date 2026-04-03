{ pkgs, ... }: {
  imports = [ ./password.nix ];

  environment.systemPackages = with pkgs; [ sops ];

  users.users.djoolz = {
    isNormalUser = true;
    description = "djoolz";
  };
}
