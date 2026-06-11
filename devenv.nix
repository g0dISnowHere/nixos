{ pkgs, lib, ... }:
let
  nixLdLibraryPath = pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ];
  flakeLinterPkg =
    if builtins.hasAttr "flake-linter" pkgs then pkgs."flake-linter" else null;
  nixFastBuildPkg = if builtins.hasAttr "nix-fast-build" pkgs then
    pkgs."nix-fast-build"
  else
    null;
in {
  packages = with pkgs;
    [ python3 nixpkgs-fmt statix deadnix markdownlint-cli shellcheck ]
    ++ lib.optional (flakeLinterPkg != null) flakeLinterPkg
    ++ lib.optional (nixFastBuildPkg != null) nixFastBuildPkg;

  env = {
    NIX_LD_LIBRARY_PATH = nixLdLibraryPath;
    NIX_LD = builtins.readFile "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
    GREET = "nixos config";
    ZDOTDIR = "/etc/zsh";
  };

  enterShell = ''
    export REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

    alias update="cd \"$REPO_ROOT\" && nix flake update"
    alias check="cd \"$REPO_ROOT\" && nix flake check"
    alias fmt="cd \"$REPO_ROOT\" && nix fmt"
    alias switch="cd \"$REPO_ROOT\" && sudo nixos-rebuild switch --flake .# 2>&1 | tee nixos-switch.log || { grep --color error nixos-switch.log && exit 1; }"
    alias test="cd \"$REPO_ROOT\" && sudo nixos-rebuild test --flake .# 2>&1 | tee nixos-switch.log || { grep --color error nixos-switch.log && exit 1; }"
    alias gc="sudo nix-collect-garbage --delete-older-than 10d && nix-collect-garbage --delete-older-than 10d && nix-store --optimise"
    alias fcheck='cd "$REPO_ROOT" && nix-fast-build \
      .#nixosConfigurations.centauri.config.system.build.toplevel \
      .#nixosConfigurations.mirach.config.system.build.toplevel \
      .#nixosConfigurations.albaldah.config.system.build.toplevel \
      .#homeConfigurations."djoolz@workstation".activationPackage'

    echo "NixOS configuration development environment"
    echo "Current system: ${pkgs.stdenv.hostPlatform.system}"
  '';
}
