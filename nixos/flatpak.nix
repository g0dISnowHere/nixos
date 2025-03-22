# Apps to be installed using flatpak
# vivaldi
# obsidian

{config, pkgs, ...}:
{
  flatpak = {
    enable = true;
    extraRemotes = [
      {
        name = "flathub";
        url = "https://flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    apps = [
      {
        name = "com.vivaldi.Vivaldi";
        extraArgs = [ "--user" ];
      }
      {
        name = "md.obsidian.Obsidian";
        extraArgs = [ "--user" ];
      }
    ];
  };
}