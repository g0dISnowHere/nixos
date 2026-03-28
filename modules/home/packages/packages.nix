{ config, pkgs, pkgs-unstable, ... }:

{
  # Packages that should be installed to the user profile.
  home.packages = with pkgs;
    [
      ## Fonts & LibreOffice ##########################################################
      ## This should part of the flatpak module.
      cantarell-fonts
      fira-code
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      nerd-fonts.open-dyslexic

      # libreoffice-qt
      hunspell
      hunspellDicts.de_DE
      hunspellDicts.en_US
      # hunspellDicts.fr_FR
      ## CLI Tools ##################################################################
      neofetch
      # nnn # terminal file manager
      # jq # A lightweight and flexible command-line JSON processor
      # yq-go # yaml processor https://github.com/mikefarah/yq
      zip
      # xz # currently incompatible with rpi-imager
      unzip
      p7zip
      file
      gnupg
      mtr # A network diagnostic tool
      iperf3
      dnsutils # `dig` + `nslookup`
      ldns # replacement of `dig`, it provides the command `drill`
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      socat # replacement of openbsd-netcat
      clinfo
      elfinfo
      nmap # A utility for network discovery and security auditing
      ipcalc # it is a calculator for the IPv4/v6 addresses
      btop # replacement of htop/nmon
      iotop # io monitoring
      iftop # network monitoring
      strace # system call monitoring
      ltrace # library call monitoring
      lsof # list open files
      lm_sensors # for `sensors` command
      pciutils # lspci
      usbutils # lsusb
      curl
      ncdu # disk usage analyzer with ncurses interface
      htop
      wget
      traceroute
      git
      smartmontools
      ##############################################################################

      ## Nix Tools #################################################################
      nix-output-monitor # https://github.com/maralorn/nix-output-monitor

      nix-tree
      # nix-sweep
      graphviz
      nix-du
      nix-query-tree-viewer
      ##############################################################################

      ## Other Packages ############################################################
      # vivaldi
      vlc
      wireshark
      webcamoid
      # ansible
      # barrier # needs an open firewall port
      # input-leap # barrier, but currently maintained
      # deskflow
      bitwarden-desktop
      # blender
      moonlight-qt
      nextcloud-client
      # gimp-with-plugins
      gparted
      # inkscape
      # kicad
      obs-studio
      orca-slicer
      # prusa-slicer
      # super-slicer-latest
      synology-drive-client
      syncthing # needs an open firewall port
      # syncthingtray
      # cacert # for eduroam
      obsidian
      # quickgui
      # hyperion-ng
      # winboat # Run Windows apps on Linux with seamless integration

      #################################################################################
      # for fritzbox flashing
      #################################################################################

      # dnsmasq
      # xinetd
      # rs-tftpd
      # tftp-hpa
      parted

      #################################################################################
      # Arduino, ESP, etc.
      #################################################################################
      esptool
      rpi-imager

      #################################################################################
      # 3D Modeling
      #################################################################################
      # kicad
      # freecad

      chromium
    ] ++ [
      #################################################################################
      ## Bleeding edge
      #################################################################################
      pkgs-unstable.devenv # This might go back to stable in the future.
      pkgs-unstable.vscode # Lol, dev is too fast and plugins depend on the latest version.
      pkgs-unstable.gh # github cli
      # pkgs-unstable.kiro
    ];

  # AI packages and tool-specific notes live in `modules/home/packages/ai-tools.nix`.
}
