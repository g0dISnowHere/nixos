{ pkgs, ... }: {
  home.packages = with pkgs; [ parted esptool rpi-imager orca-slicer ];
}
