{ config, extendModules, inputs, lib, modulesPath, pkgs, ... }:
let
  # Disko still calls qemu-common with { lib, stdenv }, but nixpkgs 25.11 now
  # expects { lib, pkgs }. Adapt the old call shape just for installTest.
  diskoLibCompat = import (inputs.disko + "/lib") {
    inherit lib;
    inherit (config.disko) rootMountPoint;
    makeTest = import "${modulesPath}/../tests/make-test-python.nix";
    eval-config = import "${modulesPath}/../lib/eval-config.nix";
    qemu-common = { lib, stdenv, ... }:
      import "${modulesPath}/../lib/qemu-common.nix" {
        inherit lib;
        pkgs = { inherit stdenv; };
      };
  };
in {
  system.build.installTest = lib.mkForce (diskoLibCompat.testLib.makeDiskoTest {
    inherit extendModules pkgs;
    name = "${config.networking.hostName}-disko";
    disko-config = builtins.removeAttrs config [ "_module" ];
    testMode = "direct";
    bootCommands = lib.attrByPath [ "bootCommands" ] [ ] config.disko.tests;
    efi = lib.attrByPath [ "efi" ] false config.disko.tests;
    enableOCR = lib.attrByPath [ "enableOCR" ] false config.disko.tests;
    extraSystemConfig = lib.attrByPath [ "extraSystemConfig" ]
      (lib.attrByPath [ "extraConfig" ] { } config.disko.tests)
      config.disko.tests;
    extraTestScript = lib.attrByPath [ "extraTestScript" ]
      (lib.attrByPath [ "extraChecks" ] "" config.disko.tests)
      config.disko.tests;
  });
}
