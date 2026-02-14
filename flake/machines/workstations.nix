{ self, inputs, ... }: {
  flake.nixosConfigurations = {
    # Centauri - Primary laptop/workstation
    # Lenovo ThinkPad laptop used for development
    centauri = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "centauri";
      role = "workstation";
      desktop = "niri";
      modules = [
        # Virtualization for development
        ../../modules/nixos/virtualisation/docker_rootless.nix
      ];
    };

    # Add more workstations here as needed
  };
}
