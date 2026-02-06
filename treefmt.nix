{ inputs, ... }: {

  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem = { config, self', inputs', pkgs, system, ... }: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        nixfmt = {
          enable = pkgs.lib.meta.availableOn pkgs.stdenv.buildPlatform
            pkgs.nixfmt-rfc-style.compiler;
          package = pkgs.nixfmt-classic;
        };

        yamlfmt.enable = true;

        black.enable = true;
      };

      settings.global.excludes = [
        "machines/*/facts/*"
        "old-machines/*/facts/*"
        "vars/*"
        "*.gpg"
        "*.pub"
        ".git-crypt/*"
        "*.png"
        "LICENSE"
        "*.gitignore"
        ".gitattributes"
      ];
    };
  };
}
