{ pkgs, ... }: {
  home.packages = with pkgs; [ bat eza fd fzf ripgrep tmux tree which zoxide ];

  programs = {
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      defaultOptions = [ "--height=40%" "--layout=reverse" "--border" ];
      fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
      changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      oh-my-zsh = {
        enable = true;
        plugins =
          [ "git" "tailscale" "docker" "docker-compose" "vscode" "direnv" ];
        theme = "robbyrussell";
      };

      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        ignoreSpace = true;
        expireDuplicatesFirst = true;
        extended = true;
        share = true;
      };

      shellAliases = {
        ls = "eza --group-directories-first";
        ll = "eza -lh --group-directories-first";
        la = "eza -lah --group-directories-first";
        lt = "eza --tree --level=2 --group-directories-first";
        cat = "bat --style=plain --paging=never";
        c = "z";
      };

      initContent = ''
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        bindkey '^[[Z' reverse-menu-complete
      '';
    };
  };
}
