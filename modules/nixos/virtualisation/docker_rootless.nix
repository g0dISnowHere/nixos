{ pkgs, ... }: {
  # Docker Rootless
  # Provides Docker daemon running without root privileges for enhanced security
  # Reference: https://nixos.wiki/wiki/Docker

  ## rootless
  virtualisation.docker = {
    enable = true;
    # https://search.nixos.org/options?from=0&size=50&sort=alpha_asc&query=virtualisation.docker
    rootless = {
      enable = true;
      setSocketVariable = true;

      # https://nixos.wiki/wiki/Docker#Changing_Docker_Daemon.27s_Data_Root
      daemon.settings = {
        userland-proxy = true;
        experimental = true;
        registry-mirrors = [ "https://mirror.gcr.io" ];
      };
    };

    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # # Fix for TLS certificate verification issues with rootless Docker
  # systemd.user.services.docker.environment = {
  #   SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
  #   SSL_CERT_DIR = "/etc/ssl/certs";
  #   # REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
  #   # CURL_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
  # };

  # environment.systemPackages = [
  #   pkgs.slirp4netns # Required for rootless Docker networking
  # ];

  ## Always needed
  users.users.djoolz.extraGroups = [ "docker" ];
  ## Another way to give access to the docker socket.
  # users.extraGroups.docker.members = [ "djoolz" ];

  # hardware.nvidia-container-toolkit.enable = true;

}
