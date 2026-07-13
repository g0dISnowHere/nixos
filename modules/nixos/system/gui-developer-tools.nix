{ pkgs-unstable, ... }: {
  environment.systemPackages = [
    pkgs-unstable.vscode
    pkgs-unstable.t3code
  ];
}
