{ pkgs, ... }: {
  home.packages = with pkgs; [
    age
    jq
    nix-output-monitor
    nix-tree
    graphviz
    nix-du
    nix-query-tree-viewer
    ssh-to-age
  ];
}
