{ ... }: {
  # Workstation Role Profile
  # Interactive desktop machine defaults. Desktop and virtualization stay explicit
  # in machine composition.

  imports = [
    ../system/base.nix
    ../system/powermanagement.nix
    ../services/mosh.nix
    ../services/tailscale-client.nix
  ];

  networking.networkmanager.enable = true;
}
