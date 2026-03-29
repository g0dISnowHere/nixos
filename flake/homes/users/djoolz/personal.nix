{ repoRoot, ... }: {
  # User-specific settings that should not live in the reusable baseline
  # profiles under flake/homes/profiles/.
  programs.git = {
    settings.user = {
      name = "g0disnowhere";
      email = "jojuble@gmail.com";
    };
    includes = [{ path = "${repoRoot}/dotfiles/git/config.inc"; }];
  };

  programs.ssh.matchBlocks = {
    centauri = {
      hostname = "centauri";
      user = "djoolz";
      identitiesOnly = true;
    };
    mirach = {
      hostname = "mirach";
      user = "djoolz";
      identitiesOnly = true;
    };
  };
}
