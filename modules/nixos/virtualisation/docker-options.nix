{ config, lib, ... }:
let cfg = config.my.virtualisation.docker;
in {
  options.my.virtualisation.docker = {
    rootful = lib.mkOption {
      type = lib.types.bool;
      default = false;
      internal = true;
      description = "Internal marker for the rootful Docker capability module.";
    };

    rootless = lib.mkOption {
      type = lib.types.bool;
      default = false;
      internal = true;
      description =
        "Internal marker for the rootless Docker capability module.";
    };
  };

  config.assertions = [{
    assertion = !(cfg.rootful && cfg.rootless);
    message =
      "Import either modules/nixos/virtualisation/docker.nix or docker_rootless.nix, not both.";
  }];
}
