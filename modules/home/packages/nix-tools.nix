{ pkgs, ... }: {
  home.packages = with pkgs; [
    nix-output-monitor
    nix-tree
    graphviz
    nix-du
    nix-query-tree-viewer
  ];
}
