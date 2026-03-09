{ config, pkgs, pkgs-unstable, ... }:

{
  # Packages that should be installed to the user profile.
  home.packages = with pkgs;
    let
      codex-latest = pkgs-unstable.codex.overrideAttrs (old: {
        version = "0.104.0";
        src = pkgs-unstable.fetchFromGitHub {
          owner = "openai";
          repo = "codex";
          rev = "rust-v0.104.0";
          hash = "sha256-spWb/msjl9am7E4UkZfEoH0diFbvAfydJKJQM1N1aoI=";
        };
      });
    in [
      ## Fonts & LibreOffice ##########################################################
      ## This should part of the flatpak module.
      cantarell-fonts
      fira-code
      # noto-fonts
      nerd-fonts.open-dyslexic

      nautilus
      # libreoffice-qt
      hunspell
      hunspellDicts.de_DE
      hunspellDicts.en_US
      # hunspellDicts.fr_FR
      ## CLI Tools ##################################################################
      neofetch
      # nnn # terminal file manager
      # ripgrep # recursively searches directories for a regex pattern
      # jq # A lightweight and flexible command-line JSON processor
      # yq-go # yaml processor https://github.com/mikefarah/yq
      # eza # A modern replacement for 'ls'
      # fzf # A command-line fuzzy finder
      zip
      # xz # currently incompatible with rpi-imager
      unzip
      p7zip
      file
      which
      tree
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
      tmux
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
      #################################################################################
      ## AI
      #################################################################################
      aider-chat-full
      gemini-cli
      crush
      # claude-code # using npm package instead
      # claude-monitor
      ripgrep
      # zed-editor
      # codex
    ] ++ [
      #################################################################################
      ## Bleeding edge
      #################################################################################
      pkgs-unstable.devenv # This might go back to stable in the future.
      pkgs-unstable.vscode # Lol, dev is too fast and plugins depend on the latest version.

      #################################################################################
      ## AI
      #################################################################################

      # codex-latest
      # pkgs-unstable.codex
      # pkgs-unstable.aider-chat-full
      pkgs-unstable.opencode
      pkgs-unstable.gh # github cli
      pkgs-unstable.fabric-ai
      # pkgs-unstable.kiro
      pkgs-unstable.antigravity

    ];
}
