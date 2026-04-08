{ ... }: {
  # Mirach is a homelab host with an optional local GUI. Do not let the
  # greeter suspend the machine just because nobody logged in.
  services.displayManager.gdm.autoSuspend = false;
}
