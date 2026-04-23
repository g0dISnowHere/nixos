{ self, inputs, ... }: {
  flake.nixosConfigurations = {
    # Centauri - Primary laptop/workstation
    # Lenovo ThinkPad laptop used for development
    centauri = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "centauri";
      desktopEnvironment = "gnome";
      enableHomeManager = true;
      modules = [
        ../../modules/nixos/system/base.nix
        ../../modules/nixos/system/powermanagement.nix
        ../../modules/nixos/services/mosh.nix
        ../../modules/nixos/services/tailscale-client.nix
        ../../modules/nixos/virtualisation/docker_rootless.nix
        { networking.networkmanager.enable = true; }
      ];
    };

    # Add more workstations here as needed
  };
}
