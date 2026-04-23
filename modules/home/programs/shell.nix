{ pkgs, ... }: {
  home.packages = with pkgs; [ bat eza fd fzf ripgrep tmux tree which zoxide ];
}
