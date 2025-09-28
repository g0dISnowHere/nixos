{ config, pkgs, ... }: {

  home.packages = [
    #(pkgs.quickemu.override { qemu_full = pkgs.qemu_kvm; })
    pkgs.quickemu
    pkgs.quickgui # Quickemu and Quickgui for managing virtual machines
  ];
}
