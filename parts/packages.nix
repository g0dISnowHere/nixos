{ inputs, ... }: {
  # Custom packages
  # Currently empty - will be populated as needed
  perSystem = { pkgs, ... }: {
    packages = {
      # Example:
      # my-tool = pkgs.callPackage ./pkgs/my-tool {};
    };
  };
}
