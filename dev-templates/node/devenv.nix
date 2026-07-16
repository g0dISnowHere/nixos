{ pkgs, ... }:
let
  node2nix = pkgs.writeShellScriptBin "node2nix" ''
    echo "node2nix is unavailable in this nixpkgs"
    exit 1
  '';
in
{
  packages =
    with pkgs;
    [
      nodejs
      pnpm
      yarn
    ]
    ++ [ node2nix ];
}
