{ pkgs, ... }:
{
  # Keep the GNOME desktop and useful local-administration tools without
  # installing consumer-facing core apps or an application store.
  environment.gnome.excludePackages = with pkgs; [
    decibels
    epiphany
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-connections
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-tecla
    gnome-weather
    loupe
    papers
    showtime
    simple-scan
    snapshot
    yelp
  ];

  services.gnome.gnome-software.enable = false;
}
