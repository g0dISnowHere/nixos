{ config, pkgs, ... }: {
  # Home Assistant Integration
  # Provides Home Assistant service with configuration directory and firewall rules
  # Reference: https://wiki.nixos.org/wiki/Home_Assistant

  services.home-assistant = {
    enable = true;

    # Path to your Home Assistant config directory
    # CUSTOMIZE: Change path to match your setup
    configDir = "/home/djoolz/Documents/15_homeassistant";

    # Use declarative configuration management
    # Set to null to opt-out and manage configuration manually
    config = {
      # Include default Home Assistant integrations
      default_config = { };
    };

    # Disable Lovelace configuration management (manage manually)
    lovelaceConfig = null;

    # Additional components/integrations to include
    # CUSTOMIZE: Add any custom integrations you need
    extraComponents = [
      # "esphome"      # ESPHome integration
      # "met"          # Weather service
      # "radio_browser" # Radio browser
    ];
  };

  # Firewall rule for Home Assistant web interface
  networking.firewall.allowedTCPPorts = [ 8123 ];

  # Note: Requires proper database setup and may need additional configuration
  # See Home Assistant documentation for advanced setup options
}
