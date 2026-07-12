{ desktopEnvironment ? null, pkgs, pkgs-unstable, inputs, ... }:
let
  nixLdLibraryPath = [ "${pkgs.zlib}/lib" "${pkgs.stdenv.cc.cc.lib}/lib" ];

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
        # pkgs-unstable.bun

        # Rust
        rustc
        cargo
        rust-analyzer
        clippy
        rustfmt

        # Nix
        inputs.nixd.packages.${pkgs.stdenv.hostPlatform.system}.nixd
        # Native build tooling
        pkgconf
        gcc
        gnumake
        cmake

        # Developer-focused newer packages
        jujutsu
        lazygit
        pkgs-unstable.devenv
        pkgs-unstable.gh
        inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.hunk

      ] ++ pkgs.lib.optionals (desktopEnvironment != null) [
        pkgs-unstable.vscode
        pkgs-unstable.antigravity
        pkgs-unstable.t3code
      ];

    localBinInPath = true;

    sessionVariables = {
      GOPATH = "$HOME/go";
      GOBIN = "$HOME/go/bin";
      PNPM_HOME = "$HOME/.local/share/pnpm";
      "pnpm_config_global_dir" = "$HOME/.local/share/pnpm/global";
      "pnpm_config_global_bin_dir" = "$HOME/.local/share/pnpm/bin";
      "pnpm_config_minimum_release_age" = "20160";
      "pnpm_config_minimum_release_age_strict" = "true";
      "pnpm_config_minimum_release_age_ignore_missing_time" = "false";
      CARGO_HOME = "$HOME/.cargo";

      # Needed for Python wheels/native extensions loaded via dlopen()
      LD_LIBRARY_PATH = nixLdLibraryPath;
    };

    extraInit = ''
      export PATH="$HOME/go/bin:$HOME/.local/share/pnpm/bin:$HOME/.cargo/bin:$PATH"

    '';
  };

  programs.nix-ld = {
    enable = true;

    # Headroom vendors helper binaries that expect the standard C++ runtime at
    # conventional FHS paths. Expose libstdc++.so.6 through nix-ld for
    # headless AI-tool installs done outside nixpkgs.
    libraries = [ pkgs.stdenv.cc.cc pkgs.zlib ];
  };

}
