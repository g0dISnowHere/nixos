{ config, pkgs, ... }: {
  services = {
    syncthing.enable = true;
    # https://github.com/gmodena/nix-flatpak
    flatpak = {
      enable = true;
      # remotes = [{
      #   name = "flathub-beta";
      #   location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      # }];
      packages = [
        # TODO Add your desired Flatpak packages here
      ];
      update = {
        onActivation = true;
        auto = {
          enable = true;
          onCalendar = "weekly"; # Default value
        };
      };
    };

  };

}
