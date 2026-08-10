{ pkgs-unstable, ... }: {
  environment.systemPackages = [
    pkgs-unstable.vscode
    pkgs-unstable.antigravity-ide
    pkgs-unstable.t3code
  ];
}
