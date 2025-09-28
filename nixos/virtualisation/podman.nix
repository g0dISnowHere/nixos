# https://nixos.wiki/wiki/Podman
{ pkgs, ... }: {
  virtualisation = {
    # Enable common container config files in /etc/containers
    containers.enable = true;
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;

      autoPrune = {
        enable = true;
        dates = "weekly";
      };

      autoUpdate = {
        enable = true;
        # Check for updates daily.
        schedule = "daily";
      };
    };
  };

  # Useful other development tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
    #podman-compose # start group of containers for dev
    podman-desktop
  ];

  # hardware.nvidia-container-toolkit.enable = true;

  # # Run podman containers as systemd services.
  # virtualisation.oci-containers= {
  #   backend = "podman";
  #   containers = {
  #     container-name = {
  #       image = "container-image";
  #       autoStart = true;
  #       ports = [ "127.0.0.1:1234:1234" ];
  #     };
  #   };
  # };
}
