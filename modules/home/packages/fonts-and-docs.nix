{ pkgs, ... }: {
  home.packages = with pkgs; [
    cantarell-fonts
    fira-code
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.open-dyslexic
    hunspell
    hunspellDicts.de_DE
    hunspellDicts.en_US
  ];
}
