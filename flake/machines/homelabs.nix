{ self, inputs, ... }: {
  flake.nixosConfigurations = {
    # Mirach - Homelab server with the same desktop stack as centauri
    # Runs Home Assistant VM, Docker services, media server
    mirach = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "mirach";
      role = "homelab";
      desktop = "gnome";
      modules = [
        # Docker for services
        ../../modules/nixos/virtualisation/docker.nix

        # Machine-specific services in machines/mirach/
      ];
    };

    # STRATO VPS - headless remote server
    # Runs on a single virtio disk and DHCP networking on ens6
    albaldah = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "albaldah";
      role = "homelab";
      modules = [
        inputs.disko.nixosModules.disko
        ../../modules/nixos/system/disko-install-test-compat.nix
        ../../nixos/machines/albaldah/disko.nix
        # Docker for services
        ../../modules/nixos/virtualisation/docker.nix
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
