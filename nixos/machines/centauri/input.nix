{ pkgs, ... }: {
  hardware = {
    trackpoint = {
      enable = true;
      device = "TPPS/2 IBM TrackPoint";
    };
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
  };

  environment.systemPackages = with pkgs; [ piper libratbag libinput ];

  services.libinput = {
    enable = true;
    mouse = { accelProfile = "flat"; };
    touchpad = {
      accelProfile = "flat";
      tapping = true;
      tappingButtonMap = "lrm";
      tappingDragLock = true;
      clickMethod = "clickfinger";
      scrollMethod = "twofinger";
      horizontalScrolling = true;
      disableWhileTyping = true;
    };
  };

  services.ratbagd.enable = true;
}
