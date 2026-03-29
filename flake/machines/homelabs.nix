{ self, inputs, ... }: {
  flake.nixosConfigurations = {
    # Mirach - Homelab server with the same desktop stack as centauri
    # Runs Home Assistant VM, Docker services, media server
    mirach = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "mirach";
      role = "homelab";
      desktop = "niri";
      modules = [
        # Docker for services
        ../../modules/nixos/virtualisation/docker.nix

        # Machine-specific services in machines/mirach/
      ];
    };

  alhena = self.lib.mkNixosSystem {
    system = "x86_64-linux";
    hostname = "alhena";
    role = "wsl";
      modules = [
        # Docker for services
        ../../modules/nixos/virtualisation/docker.nix

        # Machine-specific services in machines/alhena/
      ];
  };

    # Add more homelabs here as needed
  };
}
