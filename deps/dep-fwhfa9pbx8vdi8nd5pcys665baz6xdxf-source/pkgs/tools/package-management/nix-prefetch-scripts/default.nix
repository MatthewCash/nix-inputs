{
  lib,
  stdenv,
  makeWrapper,
  buildEnv,
  bash,
  breezy,
  coreutils,
  cvs,
  findutils,
  gawk,
  git,
  git-lfs,
  gnused,
  mercurial,
  # FIXME: These scripts should not depend on Nix, they should depend on a
  # `.nar` hasher compatible with Nix.
  #
  # The fact that these scripts depend on Nix means that e.g. Chromium depends
  # on Nix.
  #
  # Also should be fixed:
  # - prefetch-yarn-deps
  # - nurl, nix-init
  #
  # Gridlock is one such candidate: https://github.com/lf-/gridlock
  nixForLinking,
  subversion,
}:

let
  mkPrefetchScript =
    tool: src: deps:
    stdenv.mkDerivation {
      name = "nix-prefetch-${tool}";

      strictDeps = true;
      nativeBuildInputs = [ makeWrapper ];
      buildInputs = [ bash ];

      dontUnpack = true;

      installPhase = ''
        install -vD ${src} $out/bin/$name;
        wrapProgram $out/bin/$name \
          --prefix PATH : ${
            lib.makeBinPath (
              deps
              ++ [
                coreutils
                gnused
                nixForLinking
              ]
            )
          } \
          --set HOME /homeless-shelter
      '';

      preferLocalBuild = true;

      meta = with lib; {
        description = "Script used to obtain source hashes for fetch${tool}";
        maintainers = with maintainers; [ bennofs ];
        platforms = platforms.unix;
      };
    };
in
rec {
  nix-prefetch-bzr = mkPrefetchScript "bzr" ../../../build-support/fetchbzr/nix-prefetch-bzr [
    breezy
  ];
  nix-prefetch-cvs = mkPrefetchScript "cvs" ../../../build-support/fetchcvs/nix-prefetch-cvs [ cvs ];
  nix-prefetch-git = mkPrefetchScript "git" ../../../build-support/fetchgit/nix-prefetch-git [
    findutils
    gawk
    git
    git-lfs
  ];
  nix-prefetch-hg = mkPrefetchScript "hg" ../../../build-support/fetchhg/nix-prefetch-hg [
    mercurial
  ];
  nix-prefetch-svn = mkPrefetchScript "svn" ../../../build-support/fetchsvn/nix-prefetch-svn [
    subversion
  ];

  nix-prefetch-scripts = buildEnv {
    name = "nix-prefetch-scripts";

    paths = [
      nix-prefetch-bzr
      nix-prefetch-cvs
      nix-prefetch-git
      nix-prefetch-hg
      nix-prefetch-svn
    ];

    meta = with lib; {
      description = "Collection of all the nix-prefetch-* scripts which may be used to obtain source hashes";
      maintainers = with maintainers; [ bennofs ];
      platforms = platforms.unix;
    };
  };
}
