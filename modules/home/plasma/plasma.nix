{ inputs, config, lib, pkgs, ... }: {
  # Plasma Desktop — Home-Manager Settings
  # Parallel to modules/home/dconf/dconf.nix for GNOME
  # Uses plasma-manager for declarative KDE configuration
  # Reference: https://github.com/nix-community/plasma-manager

  imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

  programs.plasma = {
    enable = true;

    # KDE-specific home configuration can be added here:
    # workspace = {
    #   theme = "breeze-dark";
    #   iconTheme = "breeze-dark";
    # };

    # panels = [ ... ];
    # shortcuts = { ... };
    # configFile = { ... };
  };
}

