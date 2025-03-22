# https://wiki.nixos.org/wiki/VirtualBox

{ pkgs, ... }:
{
  virtualisation.virtualbox = {
    enable = true;
    guestAdditions = true;
    extpack.enable = true;
    enableExtensionPack = true;
    # extpack.url = "https://download.virtualbox.org/virtualbox/6.1.26/Oracle_VM_VirtualBox_Extension_Pack-6.1.26.vbox-extpack";
    # more options here: https://search.nixos.org/options?query=virtualisation.virtualbox
    guest = {
      enable = true;
      dragAndDrop = true;
      clipboard = true;
    };
  };

  # Access to virtualbox
  users.users.djoolz = {
    extraGroups = [
      "vboxusers"
      ];
  };
}