{ pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs;
      [
        intel-media-driver
        # intel-vaapi-driver # LIBVA_DRIVER_NAME=i965
        # libvdpau-va-gl
      ];
  };

  environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; };
}
