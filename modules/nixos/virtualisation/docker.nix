# https://nixos.wiki/wiki/Docker
{ pkgs, ... }: {

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

  ## Always needed
  users.users.djoolz.extraGroups = [ "docker" ];
  ## Another way to give access to the docker socket.
  # users.extraGroups.docker.members = [ "djoolz" ];

  # hardware.nvidia-container-toolkit.enable = true;

}
