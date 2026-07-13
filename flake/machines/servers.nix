{ self, ... }: {
  flake.nixosConfigurations = {
    # Mirach - local GNOME-managed virtualization and container host
    # Runs Home Assistant VM, Docker services, media server
    mirach = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "mirach";
    };

    # Albaldah - public-edge x86_64 host
    # Runs on a single virtio disk and DHCP networking on ens6
    albaldah = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "albaldah";
    };

    # Alhena - WSL x86_64 host with remote-session and container capabilities
    alhena = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "alhena";
    };

    # Add more hosts here as needed
  };
}
