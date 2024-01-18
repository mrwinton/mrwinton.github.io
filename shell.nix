{ pkgs ? import <nixpkgs> { }, lib ? pkgs.lib, stdenv ? pkgs.stdenv, ... }:

let
  ruby = pkgs.ruby_3_2;
  paths = with pkgs; [
    gcc
    git
    glib
    gnumake
    libffi
    libpcap
    libxml2
    libxslt
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodejs
    pkg-config
    ruby
    rubyPackages_3_2.ruby-vips
    vips
    zlib
    file
  ];

  env = pkgs.buildEnv {
    name = "mrwinton-github-pages-env";
    paths = paths;
    extraOutputsToInstall = [ "bin" "lib" "include" ];
  };

  makeCpath = lib.makeSearchPathOutput "include" "include";
  makePathExpression = new:
    builtins.concatStringsSep ":" [ new (builtins.getEnv "PATH") ];
in
pkgs.mkShell rec {
  name = "mrwinton-github-pages";
  buildInputs = paths;
  src = ./.;
  PROJECT_ROOT = toString ./. + "/";
  CPATH = makeCpath [ env ];
  NODE_MODULES = PROJECT_ROOT + "/node_modules/.bin";
  GEM_HOME = PROJECT_ROOT + "/.gem/ruby/${ruby.version}";
  LIBRARY_PATH = lib.makeLibraryPath [ env ];
  PATH = makePathExpression (lib.makeBinPath [ PROJECT_ROOT GEM_HOME NODE_MODULES env ]);

  shellHook = ''
    unset CC

    export PATH=${PATH}:$PATH
  '';
}
