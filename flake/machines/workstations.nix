{ self, ... }: {
  flake.nixosConfigurations = {
    # Centauri - Primary laptop
    # Lenovo ThinkPad laptop used for development
    centauri = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "centauri";
    };

    # Add more hosts here as needed
  };
}
