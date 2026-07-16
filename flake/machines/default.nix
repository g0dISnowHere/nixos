{ self, ... }: {
  flake.nixosConfigurations = {
    # Centauri - primary ThinkPad host
    centauri = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "centauri";
    };

    # Mirach - LAN virtualization host
    mirach = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "mirach";
    };

    # Albaldah - public-edge VPS
    albaldah = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "albaldah";
    };

    # Alhena - WSL host
    alhena = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "alhena";
    };
  };
}
