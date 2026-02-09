{ lib, ... }: {
  # Define the 'my' namespace for custom per-machine options
  # This module provides the option definitions without requiring specific modules to be loaded
  options.my = with lib; {
    libvirt = {
      bridgeInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description =
          "Name of the bridge interface (e.g., 'br0'). Required for bridge forwarding rules.";
      };
      physicalInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description =
          "Name of the physical interface (e.g., 'enp0s31f6'). Required for bridge forwarding rules.";
      };
    };
  };
}
