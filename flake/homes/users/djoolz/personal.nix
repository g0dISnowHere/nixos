{ ... }: {
  # User-specific settings that should not live in the reusable baseline
  # profiles under flake/homes/profiles/.
  programs.git.settings.user = {
    name = "g0disnowhere";
    email = "jojuble@gmail.com";
  };
}
