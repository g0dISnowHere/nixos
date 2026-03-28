{ config, pkgs, ... }: {
  # Something about powermanagement. FIXME source
  powerManagement.powertop.enable = true;
  systemd.services.powertop = {
    postStart = ''
      HIDDEVICES=$(ls /sys/bus/usb/drivers/usbhid | grep -oE '^[0-9]+-[0-9\.]+' | sort -u)
      for i in $HIDDEVICES; do
        echo -n "Enabling " | cat - /sys/bus/usb/devices/$i/product
        echo 'on' > /sys/bus/usb/devices/$i/power/control
      done
    '';
    # FIXME always coredumps on boot
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "2s";
    };
  };

  # Battery power management and monitoring
  # services.upower.enable = true;
  # services.tlp.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
    HandleSuspendKey = "suspend";
  };
}
