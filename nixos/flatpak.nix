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
  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    '';
  };

  environment.systemPackages = with pkgs; [
    gnome-software
    ];
  
  # users.users.djoolz = {
  #   packages = with pkgs; [
  #     flatpak
  #     gnome-software
  #   ];
  # };
}