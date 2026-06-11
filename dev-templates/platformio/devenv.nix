{ pkgs, lib, ... }: {
  packages = with pkgs;
    [
      clang-tools
      cmake
      codespell
      conan
      cppcheck
      doxygen
      gtest
      lcov
      platformio
      vcpkg
      vcpkg-tool
    ] ++ lib.optionals (stdenv.hostPlatform.system != "aarch64-darwin") [ gdb ];

  env = { PLATFORMIO_CORE_DIR = "$PWD/.platformio"; };
}
