{
  lib,
  stdenv,
  fetchurl,
  perl,
  zlib,
  buildPackages,
}:

stdenv.mkDerivation rec {
  name = "${passthru.pname}-${passthru.version}";

  passthru = {
    pname = "hspell";
    version = "1.4";
  };

  PERL_USE_UNSAFE_INC = "1";

  src = fetchurl {
    url = "${meta.homepage}${name}.tar.gz";
    hash = "sha256-cxD11YdA0h1tIVwReWWGAu99qXqBa8FJfIdkvpeqvqM=";
  };

  patches = [ ./remove-shared-library-checks.patch ];
  postPatch = "patchShebangs .";
  preBuild = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
    make CC=${buildPackages.stdenv.cc}/bin/cc find_sizes
    mv find_sizes find_sizes_build
    make clean

    substituteInPlace Makefile --replace "./find_sizes" "./find_sizes_build"
    substituteInPlace Makefile --replace "ar cr" "${lib.getBin stdenv.cc.bintools.bintools}/bin/${stdenv.cc.targetPrefix}ar cr"
    substituteInPlace Makefile --replace "ranlib" "${lib.getBin stdenv.cc.bintools.bintools}/bin/${stdenv.cc.targetPrefix}ranlib"
    substituteInPlace Makefile --replace "STRIP=strip" "STRIP=${lib.getBin stdenv.cc.bintools.bintools}/bin/${stdenv.cc.targetPrefix}strip"
  '';
  nativeBuildInputs = [
    perl
    zlib
  ];
  #  buildInputs = [ zlib ];

  meta = with lib; {
    description = "Hebrew spell checker";
    homepage = "http://hspell.ivrix.org.il/";
    platforms = platforms.all;
    license = licenses.gpl2;
  };
}
