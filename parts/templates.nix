{
  flake.templates = rec {
    default = empty;

    bun = {
      path = ../dev-templates/bun;
      description = "Bun development environment";
    };

    c-cpp = {
      path = ../dev-templates/c-cpp;
      description = "C/C++ development environment";
    };

    clojure = {
      path = ../dev-templates/clojure;
      description = "Clojure development environment";
    };

    cue = {
      path = ../dev-templates/cue;
      description = "Cue development environment";
    };

    deno = {
      path = ../dev-templates/deno;
      description = "Deno development environment";
    };

    dhall = {
      path = ../dev-templates/dhall;
      description = "Dhall development environment";
    };

    elixir = {
      path = ../dev-templates/elixir;
      description = "Elixir development environment";
    };

    elm = {
      path = ../dev-templates/elm;
      description = "Elm development environment";
    };

    empty = {
      path = ../dev-templates/empty;
      description = "Empty dev template that you can customize at will";
    };

    gleam = {
      path = ../dev-templates/gleam;
      description = "Gleam development environment";
    };

    go = {
      path = ../dev-templates/go;
      description = "Go development environment";
    };

    hashi = {
      path = ../dev-templates/hashi;
      description = "HashiCorp DevOps tools development environment";
    };

    haskell = {
      path = ../dev-templates/haskell;
      description = "Haskell development environment";
    };

    haxe = {
      path = ../dev-templates/haxe;
      description = "Haxe development environment";
    };

    java = {
      path = ../dev-templates/java;
      description = "Java development environment";
    };

    jupyter = {
      path = ../dev-templates/jupyter;
      description = "Jupyter development environment";
    };

    kotlin = {
      path = ../dev-templates/kotlin;
      description = "Kotlin development environment";
    };

    latex = {
      path = ../dev-templates/latex;
      description = "LaTeX development environment";
    };

    lean4 = {
      path = ../dev-templates/lean4;
      description = "Lean 4 development environment";
    };

    nickel = {
      path = ../dev-templates/nickel;
      description = "Nickel development environment";
    };

    nim = {
      path = ../dev-templates/nim;
      description = "Nim development environment";
    };

    nix = {
      path = ../dev-templates/nix;
      description = "Nix development environment";
    };

    node = {
      path = ../dev-templates/node;
      description = "Node.js development environment";
    };

    ocaml = {
      path = ../dev-templates/ocaml;
      description = "OCaml development environment";
    };

    odin = {
      path = ../dev-templates/odin;
      description = "Odin development environment";
    };

    opa = {
      path = ../dev-templates/opa;
      description = "Open Policy Agent development environment";
    };

    php = {
      path = ../dev-templates/php;
      description = "PHP development environment";
    };

    platformio = {
      path = ../dev-templates/platformio;
      description = "PlatformIO development environment";
    };

    protobuf = {
      path = ../dev-templates/protobuf;
      description = "Protobuf development environment";
    };

    pulumi = {
      path = ../dev-templates/pulumi;
      description = "Pulumi development environment";
    };

    purescript = {
      path = ../dev-templates/purescript;
      description = "Purescript development environment";
    };

    python = {
      path = ../dev-templates/python;
      description = "Python development environment";
    };

    r = {
      path = ../dev-templates/r;
      description = "R development environment";
    };

    ruby = {
      path = ../dev-templates/ruby;
      description = "Ruby development environment";
    };

    rust = {
      path = ../dev-templates/rust;
      description = "Rust development environment";
    };

    scala = {
      path = ../dev-templates/scala;
      description = "Scala development environment";
    };

    shell = {
      path = ../dev-templates/shell;
      description = "Shell script development environment";
    };

    swi-prolog = {
      path = ../dev-templates/swi-prolog;
      description = "SWI-Prolog development environment";
    };

    swift = {
      path = ../dev-templates/swift;
      description = "Swift development environment";
    };

    typst = {
      path = ../dev-templates/typst;
      description = "Typst development environment";
    };

    vlang = {
      path = ../dev-templates/vlang;
      description = "V development environment";
    };

    zig = {
      path = ../dev-templates/zig;
      description = "Zig development environment";
    };

    c = c-cpp;
    cpp = c-cpp;
  };
}
