# { config, pkgs, ... }:

# {

#   programs = {
#     # Install firefox
#     # TODO what is the difference between programs, services and packages?
#     firefox.enable = true;
#     };

#   services = {
#     # Enable flatpak support
#     flatpak.enable = true;
#     # enable the tailscale service
#     # TODO needs an open firewall port
#     tailscale.enable = true;
#     };

#   nixpkgs = {
#     config = {
#       # Allow unfree packages: not fully free and opensource software.
#       allowUnfree = true;
#       };
#     # TODO: understand overlay
#     overlays = [
#       # If you want to use overlays exported from other flakes:
#       # neovim-nightly-overlay.overlays.default

#       # Or define it inline, for example:
#       # (final: prev: {
#       #   hi = final.hello.overrideAttrs (oldAttrs: {
#       #     patches = [ ./change-hello-to-hi.patch ];
#       #   });
#       # })
#     ];
#   };

#   # List packages installed in system profile. They are installed for every user on the system.
#   # To search, run: nix search wget
#   environment.systemPackages = with pkgs; [
#     curl
#     htop
#     # nixos-conf-editor
#     # nix-software-center
#     wget
#     smartmontools
#     pkgs.ansible
#     pkgs.barrier # needs an open firewall port
#     pkgs.bitwarden
#     pkgs.blender
#     pkgs.clinfo
#     pkgs.direnv
#     # pkgs.dnsmasq
#     pkgs.elfinfo
#     pkgs.moonlight-qt
#     pkgs.nextcloud-client
#     pkgs.gimp-with-plugins
#     pkgs.git
#     pkgs.glxinfo
#     pkgs.gparted
#     pkgs.inkscape
#     pkgs.kicad
#     pkgs.libreoffice-qt6-still
#     pkgs.nix-tree
#     pkgs.obs-studio
#     pkgs.orca-slicer
#     pkgs.pciutils
#     pkgs.prusa-slicer
#     pkgs.python312
#     pkgs.spotify
#     pkgs.super-slicer-latest
#     pkgs.synology-drive-client    
#     pkgs.syncthing # needs an open firewall port
#     pkgs.syncthingtray
#     # pkgs.tailscale # needs an open firewall port. FIXME duplicate?
#     pkgs.vlc
#     pkgs.vscode
#     pkgs.vulkan-tools
#     # wayland-info
#     pkgs.wireshark
#     pkgs.webcamoid
#     pkgs.xsane
#   ];

# }