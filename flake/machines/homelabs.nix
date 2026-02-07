{ self, inputs, ... }:
{
  flake.nixosConfigurations = {
    # Mirach - Homelab server with optional GUI
    # Runs Home Assistant VM, Docker services, media server
    mirach = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "mirach";
      role = "homelab";
      modules = [
        # GUI for management interface
        ../modules/nixos/desktop/gnome.nix

        # Virtualization for Home Assistant VM
        ../modules/nixos/virtualisation/libvirtd.nix

        # Docker for services
        ../modules/nixos/virtualisation/docker.nix

        # Machine-specific services in machines/mirach/
      ];
    };

    # Add more homelabs here as needed
  };
}
