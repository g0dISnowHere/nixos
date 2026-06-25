{ desktopEnvironment ? null, pkgs, pkgs-unstable, ... }:
let
  nixLdLibraryPath = [
    "${pkgs.zlib}/lib"
    "${pkgs.stdenv.cc.cc.lib}/lib"
  ];

  uvWrapped = pkgs.symlinkJoin {
    name = "uv-wrapped";
    paths = [ pkgs.uv ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/uv \
        --set NIX_LD /run/current-system/sw/share/nix-ld/lib/ld.so \
        --set NIX_LD_LIBRARY_PATH /run/current-system/sw/share/nix-ld/lib \
        --set UV_NO_MANAGED_PYTHON 1 \
        --set UV_PYTHON_DOWNLOADS never \
        --set UV_PYTHON python3.13 \
        --set LD_LIBRARY_PATH ${pkgs.lib.concatStringsSep ":" nixLdLibraryPath}
      wrapProgram $out/bin/uvx \
        --set NIX_LD /run/current-system/sw/share/nix-ld/lib/ld.so \
        --set NIX_LD_LIBRARY_PATH /run/current-system/sw/share/nix-ld/lib \
        --set UV_NO_MANAGED_PYTHON 1 \
        --set UV_PYTHON_DOWNLOADS never \
        --set UV_PYTHON python3.13 \
        --set LD_LIBRARY_PATH ${pkgs.lib.concatStringsSep ":" nixLdLibraryPath}
    '';
  };
in {
  environment = {
    systemPackages = with pkgs;
      [
        # Python
        python3
        python3Packages.pip
        python3Packages.setuptools
        python3Packages.wheel
        python3Packages.virtualenv
        # python3Packages.pipx
        uvWrapped


        # Go
        go
        gopls
        go-tools

        # JavaScript / Node.js
        nodejs
        npm-check-updates
        yarn
        pnpm

        # Rust
        rustc
        cargo
        rust-analyzer
        clippy
        rustfmt

        # Native build tooling
        pkgconf
        gcc
        gnumake
        cmake

        # Developer-focused newer packages
        pkgs-unstable.devenv
        pkgs-unstable.gh
      ] ++ pkgs.lib.optionals (desktopEnvironment != null) [
        pkgs-unstable.vscode
        pkgs-unstable.antigravity
        pkgs-unstable.t3code
      ];

    localBinInPath = true;

    sessionVariables = {
      GOPATH = "$HOME/go";
      GOBIN = "$HOME/go/bin";
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
      CARGO_HOME = "$HOME/.cargo";

      # Needed for Python wheels/native extensions loaded via dlopen()
      LD_LIBRARY_PATH = nixLdLibraryPath;
    };

    extraInit = ''
      export PATH="$HOME/go/bin:$HOME/.npm-global/bin:$HOME/.cargo/bin:$PATH"

    '';
  };

  programs.nix-ld = {
    enable = true;

    # Headroom vendors helper binaries that expect the standard C++ runtime at
    # conventional FHS paths. Expose libstdc++.so.6 through nix-ld for
    # headless AI-tool installs done outside nixpkgs.
    libraries = [ pkgs.stdenv.cc.cc pkgs.zlib];
  };

}
