{
  # https://nixos.wiki/wiki/Automatic_system_upgrades
  # Automatic upgrades.
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    # flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "14:00";
    randomizedDelaySec = "45min";
  };
}