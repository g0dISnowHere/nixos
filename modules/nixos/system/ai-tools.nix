{ pkgs, pkgs-unstable, ... }: {
  environment.systemPackages = [
    pkgs.ripgrep
    pkgs.bubblewrap
    pkgs.rtk
    pkgs-unstable.opencode
    pkgs-unstable.fabric-ai
  ];

  environment.sessionVariables.OPENAI_BASE_URL =
    "https://headroom.int.djoolz.de";

  # Codex can run inside a sandbox that expects bwrap at /usr/bin/bwrap as a
  # sandbox helper. Keep the system bubblewrap available there on NixOS hosts.
  systemd.tmpfiles.rules =
    [ "L+ /usr/bin/bwrap - - - - ${pkgs.bubblewrap}/bin/bwrap" ];
}
