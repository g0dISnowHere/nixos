{ config, pkgs, pkgs-unstable, ... }:

{
  # Packages that should be installed to the user profile.
  home.packages = with pkgs;
    [
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
      ldns # replacement of `dig`, it provide the command `drill`
      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      socat # replacement of openbsd-netcat
      clinfo
      elfinfo
      # dnsmasq
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
      htop
      wget
      traceroute
      git
      smartmontools
      tmux
      ##############################################################################

      ## Nix Tools #################################################################
      dconf2nix
      nix-output-monitor # https://github.com/maralorn/nix-output-monitor
      nix-tree
      direnv # for managing environment variables https://ianthehenry.com/posts/how-to-learn-nix/nix-direnv/
      nix-direnv # for managing environment variables https://ianthehenry.com/posts/how-to-learn-nix/nix-direnv/
      ##############################################################################

      ## Other Packages ############################################################
      vlc
      # barrier # needs an open firewall port
      # input-leap # barrier, but currently maintained
      deskflow
      bitwarden
      # blender
      moonlight-qt
      nextcloud-client
      gparted
      orca-slicer
      # prusa-slicer
      # super-slicer-latest
      synology-drive-client
      syncthing # needs an open firewall port
      # syncthingtray
      # cacert # for eduroam
      obsidian
      rpi-imager
      zigbee2mqtt_2
    ] ++ [
      pkgs-unstable.devenv # This might go back to stable in the future.
      pkgs-unstable.vscode # Lol, dev is too fast and plugins depend on the latest version.
    ];
}
