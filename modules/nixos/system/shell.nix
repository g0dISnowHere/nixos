{ pkgs, pkgs-zellij, ... }: {
  # Shared interactive shell defaults belong at the system layer so headless
  # machines get the same baseline even without Home Manager.
  environment.systemPackages = with pkgs; [
    bat
    direnv
    eza
    fd
    fzf
    mosh
    ripgrep
    tmux
    tree
    which
    pkgs-zellij.zellij
    zoxide
  ];
  fonts = {
    packages = with pkgs; [ nerd-fonts.jetbrains-mono ];
    fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font Mono" ];
  };

  users.defaultUserShell = pkgs.zsh;

  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

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
      # Prefer pnpm in interactive shells. Keep npm compatibility narrow so
      # common muscle-memory commands work without pretending npm and pnpm are
      # fully interchangeable.
      interactiveShellInit = ''
        alias npx='pnpm dlx'
        alias pnpx='pnpm dlx'

        npm() {
          if (( $# == 0 )); then
            command pnpm
            return
          fi

          local subcommand="$1"
          shift

          case "$subcommand" in
            install|i)
              if (( $# == 0 )); then
                command pnpm install
              else
                command pnpm add "$@"
              fi
              ;;
            add)
              command pnpm add "$@"
              ;;
            uninstall|remove|rm)
              command pnpm remove "$@"
              ;;
            update|upgrade|up)
              command pnpm update "$@"
              ;;
            ci)
              command pnpm install --frozen-lockfile "$@"
              ;;
            exec)
              command pnpm exec "$@"
              ;;
            run)
              command pnpm run "$@"
              ;;
            create)
              command pnpm create "$@"
              ;;
            init)
              if (( $# > 0 )) && [[ "$1" != -* ]]; then
                command pnpm create "$@"
              else
                command pnpm init "$@"
              fi
              ;;
            test|start|pack|publish|outdated|why|view|info)
              command pnpm "$subcommand" "$@"
              ;;
            *)
              print -u2 "npm -> pnpm wrapper: unsupported subcommand '$subcommand'; use pnpm directly."
              return 1
              ;;
          esac
        }

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
