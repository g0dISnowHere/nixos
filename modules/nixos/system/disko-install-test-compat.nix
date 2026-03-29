{
  config,
  extendModules,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  # Disko still calls qemu-common with { lib, stdenv }, but nixpkgs 25.11 now
  # expects { lib, pkgs }. Adapt the old call shape just for installTest.
  diskoLibCompat = import (inputs.disko + "/lib") {
    inherit lib;
    rootMountPoint = config.disko.rootMountPoint;
    makeTest = import "${modulesPath}/../tests/make-test-python.nix";
    eval-config = import "${modulesPath}/../lib/eval-config.nix";
    qemu-common =
      {
        lib,
        stdenv,
        ...
      }:
      import "${modulesPath}/../lib/qemu-common.nix" {
        inherit lib;
        pkgs = { inherit stdenv; };
      };
  };
in
{
  system.build.installTest = lib.mkForce (diskoLibCompat.testLib.makeDiskoTest {
    inherit extendModules pkgs;
    name = "${config.networking.hostName}-disko";
    disko-config = builtins.removeAttrs config [ "_module" ];
    testMode = "direct";
    bootCommands = config.disko.tests.bootCommands;
    efi = config.disko.tests.efi;
    enableOCR = config.disko.tests.enableOCR;
    extraSystemConfig = config.disko.tests.extraConfig;
    extraTestScript = config.disko.tests.extraChecks;
  });
}
