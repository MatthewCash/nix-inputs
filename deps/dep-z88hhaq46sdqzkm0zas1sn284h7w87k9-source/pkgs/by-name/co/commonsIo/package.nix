{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  version = "2.17.0";
  pname = "commons-io";

  src = fetchurl {
    url = "mirror://apache/commons/io/binaries/${pname}-${version}-bin.tar.gz";
    sha256 = "sha256-4CM53Ujdtt0E9zAg9ytOa7UIw5bGNz/zrZqKJOQM9bg=";
  };

  installPhase = ''
    tar xf ${src}
    mkdir -p $out/share/java
    cp *.jar $out/share/java/
  '';

  meta = {
    homepage = "https://commons.apache.org/proper/commons-io";
    description = "Library of utilities to assist with developing IO functionality";
    maintainers = with lib.maintainers; [ copumpkin ];
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    license = lib.licenses.asl20;
    platforms = with lib.platforms; unix;
  };
}
