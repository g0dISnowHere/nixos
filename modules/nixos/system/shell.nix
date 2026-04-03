{ pkgs, ... }: {
  # Shared interactive shell defaults belong at the system layer so headless
  # machines get the same baseline even without Home Manager.
  environment.systemPackages =
    with pkgs; [ bat eza fd fzf ripgrep tmux tree which zoxide ];

  users.defaultUserShell = pkgs.zsh;

  programs = {
    fzf = {
      fuzzyCompletion = true;
      keybindings = true;
    };

    zoxide.enable = true;

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ls = "eza --group-directories-first";
        ll = "eza -lh --group-directories-first";
        la = "eza -lah --group-directories-first";
        lt = "eza --tree --level=2 --group-directories-first";
        cat = "bat --style=plain --paging=never";
        c = "z";
      };
      histSize = 50000;
      interactiveShellInit = ''
        SAVEHIST=50000
        setopt HIST_IGNORE_DUPS
        setopt HIST_IGNORE_SPACE
        setopt HIST_EXPIRE_DUPS_FIRST
        setopt EXTENDED_HISTORY
        setopt SHARE_HISTORY

        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        bindkey '^[[Z' reverse-menu-complete
      '';
      ohMyZsh = {
        enable = true;
        plugins =
          [ "git" "tailscale" "docker" "docker-compose" "vscode" "direnv" ];
        theme = "robbyrussell";
      };
    };
  };
}
