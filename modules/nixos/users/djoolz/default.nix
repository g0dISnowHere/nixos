{ pkgs, ... }: {
  imports = [
    ./password.nix
    ./chezmoi-secrets.nix
  ];

  environment.systemPackages = with pkgs; [ sops ];

  users.users.djoolz = {
    isNormalUser = true;
    linger = true;
    description = "djoolz";
  };
}
