{ config, pkgs, ... }:
{
  # If you want to use modules from other flakes (such as nixos-hardware):
  # inputs.hardware.nixosModules.common-cpu-amd
  # inputs.hardware.nixosModules.common-ssd
  
  # Enable Blueteeth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    };
  
  # Graphics drivers
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # ... # your Open GL, Vulkan and VAAPI drivers
      intel-media-sdk
      # # https://wiki.nixos.org/wiki/Intel_Graphics
      # vpl-gpu-rt # or intel-media-sdk for QSV
      ];
    };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with pipewire.
  # sound.enable = true;    
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
    };

  # Enable touchpad support (enabled default in most desktopManager).
  # https://nixos.org/manual/nixos/stable/options
  services.libinput = {
    enable = true;
    };
}