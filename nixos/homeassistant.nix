# https://wiki.nixos.org/wiki/Home_Assistant
{ config, pkgs, ... }: {

  services.home-assistant = {
    enable = true;
    # # opt-out from declarative configuration management
    # config = null;

    # Includes dependencies for a basic setup
    # https://www.home-assistant.io/integrations/default_config/
    config.default_config = { };
    lovelaceConfig = null;
    # configure the path to your config directory
    configDir = "/home/djoolz/Documents/15_homeassistant";
    # specify list of components required by your configuration
    extraComponents = [
      # "esphome"
      # "met"
      # "radio_browser"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 8123 ]; # Home Assistant default port
}
