{
  isNixosIntegrated ? false,
  lib,
  repoRoot,
  ...
}:
{
  # User-specific settings that should not live in the reusable baseline
  # profiles under flake/homes/profiles/.
  programs.git = {
    settings.user = {
      name = "g0disnowhere";
      email = "jojuble@gmail.com";
    };
    includes = [ { path = "${repoRoot}/dotfiles/git/config.inc"; } ];
  };

  programs.ssh.settings = lib.optionalAttrs (!isNixosIntegrated) {
    centauri = {
      HostName = "centauri";
      User = "djoolz";
      IdentitiesOnly = true;
    };
    albaldah = {
      HostName = "albaldah";
      User = "djoolz";
      IdentitiesOnly = true;
    };
    albaldah-root = {
      HostName = "albaldah";
      User = "root";
      IdentitiesOnly = true;
    };
    mirach = {
      HostName = "192.168.3.223";
      User = "djoolz";
      IdentitiesOnly = true;
    };
    mirach-root = {
      HostName = "192.168.3.223";
      User = "root";
      IdentitiesOnly = true;
    };
    alhena = {
      HostName = "192.168.3.211";
      User = "djoolz";
      IdentitiesOnly = true;
    };
    alhena-root = {
      HostName = "192.168.3.211";
      User = "root";
      IdentitiesOnly = true;
    };
  };
}
