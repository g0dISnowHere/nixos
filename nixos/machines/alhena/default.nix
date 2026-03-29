{ hostname, inputs, lib, pkgs, ... }: {
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../../../modules/nixos/services/vscode-remote.nix
  ];

  networking.hostName = hostname;

  wsl = {
    enable = true;
    defaultUser = "djoolz";
    startMenuLaunchers = true;
  };

  users.users.djoolz = {
    isNormalUser = true;
    description = "djoolz";
    extraGroups = [ "wheel" ];
  };

  home-manager.users.djoolz =
    import ../../../flake/homes/users/djoolz/server.nix;

  environment.systemPackages = with pkgs; [ git curl htop tmux vim ];

  system.stateVersion = lib.mkDefault "25.11";
}
