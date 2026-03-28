{ pkgs, ... }: {
  home.packages = with pkgs; [
    age
    nix-output-monitor
    nix-tree
    graphviz
    nix-du
    nix-query-tree-viewer
    sops
    ssh-to-age
  ];
}
