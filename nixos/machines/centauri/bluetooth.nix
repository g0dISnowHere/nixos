_: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
        FastConnectable = true;
      };
      Policy = { AutoEnable = true; };
      # extraConfig = "load-module module-switch-on-connect";
    };
  };
}
