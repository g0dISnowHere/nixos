{ ... }: {
  # Flatpak infrastructure only. Application sets live under modules/nixos/flatpak/.
  # Reference: https://github.com/gmodena/nix-flatpak

  services.flatpak = {
    enable = true;

    # Optional: Add custom Flathub beta repository.
    # remotes = [{
    #   name = "flathub-beta";
    #   location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
    # }];

    update = {
      onActivation = true;
      auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };
}
