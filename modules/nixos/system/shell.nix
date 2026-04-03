{ pkgs, ... }: {
  # Shared interactive shell defaults belong at the system layer so headless
  # machines get the same baseline even without Home Manager.
  environment.systemPackages =
    with pkgs; [ bat eza fd fzf mosh ripgrep tmux tree which zellij zoxide ];

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

        # Use one default persistent session for plain terminal SSH/mosh.
        # Keep VS Code remote terminals as normal shells and only print a hint.
        if [[ -n "$SSH_TTY" && -z "$ZELLIJ" ]] && command -v zellij >/dev/null 2>&1; then
          if [[ -n "$VSCODE_IPC_HOOK_CLI" || "$TERM_PROGRAM" == "vscode" ]]; then
            print -P "%F{yellow}zellij available:%f run 'zellij attach -c remote'"
          else
            exec zellij attach -c remote
          fi
        fi
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
