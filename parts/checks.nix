{ inputs, ... }:
{
  # CI checks and validations
  # Currently empty - will be populated with tests
  perSystem = { pkgs, ... }: {
    checks = {
      # Example:
      # treefmt = config.treefmt.build.check;
    };
  };
}
