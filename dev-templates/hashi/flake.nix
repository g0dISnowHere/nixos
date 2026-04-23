{
  description =
    "A Nix-flake-based development environment for Terraform, Packer, and Nomad";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11"; # unstable Nixpkgs

  outputs = { self, ... }@inputs:

    let
      supportedSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f:
        inputs.nixpkgs.lib.genAttrs supportedSystems (system:
          f {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
          });
    in {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            packer
            terraform
            tflint
            nomad
            vault
            nomad-autoscaler
            nomad-pack
            levant
            damon
            terragrunt
          ];
        };
      });
    };
}
