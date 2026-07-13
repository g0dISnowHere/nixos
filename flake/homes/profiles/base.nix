{
  lib,
  isNixosIntegrated ? false,
  ...
}:
{
  # Base home-manager configuration.
  # Shared across all profiles and provides CLI essentials.
  # This is the minimal profile for headless systems.

  imports = [
    # Import user modules
    ../../../modules/home/programs/programs.nix
    ../../../modules/home/programs/ssh.nix
  ]
  ++ lib.optionals (!isNixosIntegrated) [
    ../../../modules/home/packages/system-utils.nix
    ../../../modules/home/packages/nix-tools.nix
    ../../../modules/home/programs/shell.nix
  ];
}
