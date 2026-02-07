{ self, inputs, ... }:
{
  flake.nixosConfigurations = {
    # Centauri - Primary laptop/workstation
    # Lenovo ThinkPad laptop used for development
    centauri = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "centauri";
      role = "workstation";
      modules = [
        # Desktop environment
        ../../modules/nixos/desktop/gnome.nix

        # Virtualization for development
        ../../modules/nixos/virtualisation/docker-rootless.nix
      ];
    };

    # Add more workstations here as needed
  };
}
