# Apps to be installed using flatpak
# vivaldi
# obsidian

{config, pkgs, ...}:
{
  services.flatpak = {
    enable = true;
    # apps = [
    #   {
    #     name = "com.vivaldi.Vivaldi";
    #     extraArgs = [ "--user" ];
    #   }
    #   {
    #     name = "md.obsidian.Obsidian";
    #     extraArgs = [ "--user" ];
    #   }
    # ];
  };
}