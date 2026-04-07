{ self, inputs, ... }: {
  flake.nixosConfigurations = {
    # Centauri - Primary laptop/workstation
    # Lenovo ThinkPad laptop used for development
    centauri = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "centauri";
      role = "workstation";
      desktopEnvironment = "gnome";
      enableHomeManager = true;
      modules = [ ../../modules/nixos/virtualisation/docker_rootless.nix ];
    };

  };
}
