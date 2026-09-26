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
      HostName = "alhena.wallaby-clownfish.ts.net";
      User = "djoolz";
      IdentitiesOnly = true;
      KexAlgorithms = "curve25519-sha256";
    };
    alhena-root = {
      HostName = "alhena.wallaby-clownfish.ts.net";
      User = "root";
      IdentitiesOnly = true;
      KexAlgorithms = "curve25519-sha256";
    };
    "alhena.wallaby-clownfish.ts.net" = {
      KexAlgorithms = "curve25519-sha256";
    };
  };
}
