{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    age
    nix-output-monitor
    nix-tree
    graphviz
    nix-du
    nix-query-tree-viewer
    ssh-to-age
  ];
}
