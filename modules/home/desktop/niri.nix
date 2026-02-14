{ config, lib, pkgs, ... }:
let
  dotfilesRoot =
    "${config.home.homeDirectory}/Documents/01_config/mine/dotfiles";
  linkScript = "${dotfilesRoot}/scripts/link.sh";
in {
  home.activation.linkNiriDotfiles =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -x "${linkScript}" ]; then
        "${linkScript}"
      elif [ -f "${linkScript}" ]; then
        ${pkgs.bash}/bin/bash "${linkScript}"
      else
        echo "dotfiles link script not found: ${linkScript}" >&2
      fi
    '';

}
