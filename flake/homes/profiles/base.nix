{ ... }:
{
  # Base home-manager configuration.
  # Shared across all user environments and kept intentionally minimal.

  imports = [
    ../../../modules/home/programs/programs.nix
    ../../../modules/home/programs/ssh.nix
  ];
}
