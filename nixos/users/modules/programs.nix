{ config, pkgs, ... }:

{
  # Install firefox.
  programs = {
    # firefox.enable = true;

    # basic configuration of git, please change to your own
    git = {
      enable = true;
      settings.user.email = "g0disnowhere";
      settings.user.name = "jojuble";
    };

    direnv = {
      enable = true;
      enableBashIntegration = true; # see note on other shells below
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    # bash.enable = true; # see note on other shells below

    # thunderbird = {
    #   enable = true;
    # };
    #   # starship - an customizable prompt for any shell
    #   starship = {
    #     enable = true;
    #     # custom settings
    #     settings = {
    #       add_newline = false;
    #       aws.disabled = true;
    #       gcloud.disabled = true;
    #       line_break.disabled = true;
    #     };
    #   };

    #   # alacritty - a cross-platform, GPU-accelerated terminal emulator
    #   alacritty = {
    #     enable = true;
    #     # custom settings
    #     settings = {
    #       env.TERM = "xterm-256color";
    #       font = {
    #         size = 12;
    #         draw_bold_text_with_bright_colors = true;
    #       };
    #       scrolling.multiplier = 5;
    #       selection.save_to_clipboard = true;
    #     };
    #   };

    # bash = {
    #   enable = true;
    #   enableCompletion = true;
    #   # TODO add your custom bashrc here
    #   #     bashrcExtra = ''
    #   #       export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
    #   #     '';

    #   # set some aliases, feel free to add more or remove some
    #   shellAliases = {
    #     #       k = "kubectl";
    #     #       urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
    #     #       urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";

    #     update =
    #       "cd ~/Documents/01_config/mine && sudo nixos-rebuild switch --flake ~/Documents/01_config/mine#";
    #   };
    # };
  };
}
