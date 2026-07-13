let
  sys = builtins.getFlake (toString ./.);
in
builtins.attrNames sys.nixosConfigurations.centauri._module.specialArgs
