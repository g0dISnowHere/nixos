# https://nixos.wiki/wiki/Docker
{ pkgs, ... }: {
  imports = [ ./docker-options.nix ];

  my.virtualisation.docker.rootful = true;

  virtualisation.docker = {
    enable = true;
    # https://nixos.wiki/wiki/Docker#Changing_Docker_Daemon.27s_Data_Root
    daemon.settings = {
      # userland-proxy = true;
      experimental = true;
      registry-mirrors = [ "https://mirror.gcr.io" ];
    };

    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  users.users.djoolz.extraGroups = [ "docker" ];

  # hardware.nvidia-container-toolkit.enable = true;
}
