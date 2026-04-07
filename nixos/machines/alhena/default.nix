{ hostname, inputs, pkgs, ... }: {
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../../../modules/nixos/services/vscode-remote.nix
  ];

  networking.hostName = hostname;

  wsl = {
    enable = true;
    defaultUser = "djoolz";
    startMenuLaunchers = true;
  };

  # Hardware configuration for NVIDIA GPU support in containers
  hardware.nvidia-container-toolkit = {
    enable = true;
    suppressNvidiaDriverAssertion =
      true; # Suppress assertion since NVIDIA driver is provided by WSL/Windows host
  };

  users.users.djoolz.extraGroups = [ "wheel" ];

  environment.systemPackages = with pkgs; [ git curl htop tmux vim ];

  # Do not change casually. See docs/architecture/state-version-reasons.md.
  system.stateVersion = "25.11";
}
