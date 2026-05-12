{ lib, ... }: {
  # Mirach is a homelab host with an optional local GUI. Do not let the
  # greeter suspend the machine just because nobody logged in.
  services.displayManager.gdm.autoSuspend = false;

  # Keep homelab workloads running when lid closes.
  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkForce "ignore";
    HandleLidSwitchExternalPower = lib.mkForce "ignore";
    HandleLidSwitchDocked = lib.mkForce "ignore";
  };
}
