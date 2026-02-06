# https://nixos.wiki/wiki/Android

# Below is unused AI slop.
{ config, pkgs, ... }:

{
  programs.android = {
    enable = true;
    sdk.enable = true;
    sdk.packages = with pkgs.androidsdk.packages; [
      "platform-tools"
      "build-tools;33.0.2"
      "platforms;android-33"
      "emulator"
      "system-images;android-33;google_apis;x86_64"
    ];
    adb.enable = true;
  };

  # Optional: Enable Android Studio
  programs.android-studio = {
    enable = true;
    package = pkgs.android-studio;
  };
}
