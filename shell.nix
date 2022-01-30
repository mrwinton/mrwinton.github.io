with import
  (fetchTarball "https://github.com/NixOS/nixpkgs/archive/8bd7d6d6e0994aea4d2f2d42b7283db497dd5c30.tar.gz")
{
  overlays = [
    (self: super: {
      vips = super.vips.override { libjxl = null; };
    })
  ];
};
let
  ruby = pkgs.ruby_3_0;
  gems = bundlerEnv {
    name = "mrwinton-blog";
    ruby = ruby_3_0;
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;

    gemConfig = pkgs.defaultGemConfig // {
      ruby-vips = attrs: {
        postInstall = ''
          cd "$(cat $out/nix-support/gem-meta/install-path)"
          substituteInPlace lib/vips.rb \
            --replace "library_name('vips', 42)" '"${lib.getLib vips}/lib/libvips${stdenv.hostPlatform.extensions.sharedLibrary}"' \
            --replace "library_name('glib-2.0', 0)" '"${glib.out}/lib/libglib-2.0${stdenv.hostPlatform.extensions.sharedLibrary}"' \
            --replace "library_name('gobject-2.0', 0)" '"${glib.out}/lib/libgobject-2.0${stdenv.hostPlatform.extensions.sharedLibrary}"'
        '';
      };
    };
  };
in
pkgs.mkShell {
  buildInputs = [ pkg-config zlib libiconv gems (lowPrio gems.wrappedRuby) bundix nodejs nodePackages.typescript nodePackages.typescript-language-server vips ];
}
