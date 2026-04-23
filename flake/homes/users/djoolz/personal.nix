{ isNixosIntegrated ? false, lib, repoRoot, ... }: {
  # User-specific settings that should not live in the reusable baseline
  # profiles under flake/homes/profiles/.
  programs.git = {
    settings.user = {
      name = "g0disnowhere";
      email = "jojuble@gmail.com";
    };
    includes = [{ path = "${repoRoot}/dotfiles/git/config.inc"; }];
  };

  programs.ssh.matchBlocks = lib.optionalAttrs (!isNixosIntegrated) {
    centauri = {
      hostname = "centauri";
      user = "djoolz";
      identitiesOnly = true;
    };
    albaldah = {
      hostname = "85.215.175.36";
      user = "djoolz";
      identitiesOnly = true;
    };
    albaldah-root = {
      hostname = "85.215.175.36";
      user = "root";
      identitiesOnly = true;
    };
    mirach = {
      hostname = "192.168.3.223";
      user = "djoolz";
      identitiesOnly = true;
    };
    mirach-root = {
      hostname = "192.168.3.223";
      user = "root";
      identitiesOnly = true;
    };
    alhena = {
      hostname = "192.168.3.211";
      user = "djoolz";
      identitiesOnly = true;
    };
    alhena-root = {
      hostname = "192.168.3.211";
      user = "root";
      identitiesOnly = true;
    };
  };
}
