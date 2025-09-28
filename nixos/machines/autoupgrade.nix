{
  # https://nixos.wiki/wiki/Automatic_system_upgrades
  # Automatic upgrades.
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    # flake = inputs.self.outPath;
    flags = [
      # "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "14:00";
    randomizedDelaySec = "45min";
  };

  # Also enable garbage collection of old generations.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    # options = "--delete-older-than 10d";
  };

  # Enable automatic nix-store optimisation.
  nix.optimise = {
    automatic = true;
    # dates = [ "12:45" ]; # Optional; allows customizing optimisation schedule
  };
}
