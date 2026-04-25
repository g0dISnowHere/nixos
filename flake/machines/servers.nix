{ self, inputs, ... }: {
  flake.nixosConfigurations = {
    # Mirach - server-like host with local GNOME management
    # Runs Home Assistant VM, Docker services, media server
    mirach = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "mirach";
      desktopEnvironment = "gnome";
      enableHomeManager = true;
      modules = [
        ../../modules/nixos/system/base.nix
        ../../modules/nixos/services/ssh-server.nix
        ../../modules/nixos/services/tailscale-router.nix
        ../../modules/nixos/virtualisation/docker.nix
        { networking.networkmanager.enable = true; }
      ];
    };

    # STRATO VPS - headless remote server
    # Runs on a single virtio disk and DHCP networking on ens6
    albaldah = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "albaldah";
      modules = [
        ../../modules/nixos/system/base.nix
        ../../modules/nixos/services/ssh-server.nix
        ../../modules/nixos/services/crowdsec.nix
        ../../modules/nixos/services/tailscale-router.nix
        ../../modules/nixos/virtualisation/docker.nix
        inputs.disko.nixosModules.disko
        ../../modules/nixos/system/disko-install-test-compat.nix
        ../../nixos/machines/albaldah/disko.nix
      ];
    };

    # Alhena - server-like WSL environment, close to albaldah with WSL platform constraints
    alhena = self.lib.mkNixosSystem {
      system = "x86_64-linux";
      hostname = "alhena";
      modules = [
        ../../modules/nixos/system/base.nix
        ../../modules/nixos/system/wsl.nix
        ../../modules/nixos/services/ssh-server.nix
        ../../modules/nixos/services/tailscale-client.nix
        ../../modules/nixos/virtualisation/docker.nix
      ];
    };

    # Add more server-like machines here as needed
  };
}
