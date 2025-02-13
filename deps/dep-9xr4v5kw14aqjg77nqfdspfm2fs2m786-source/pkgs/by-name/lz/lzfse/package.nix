{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation rec {
  pname = "lzfse";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "lzfse";
    repo = "lzfse";
    rev = "lzfse-${version}";
    sha256 = "1mfh6y6vpvxsdwmqmfbkqkwvxc0pz2dqqc72c6fk9sbsrxxaghd5";
  };

  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    homepage = "https://github.com/lzfse/lzfse";
    description = "Reference C implementation of the LZFSE compressor";
    longDescription = ''
      This is a reference C implementation of the LZFSE compressor introduced in the Compression library with OS X 10.11 and iOS 9.
      LZFSE is a Lempel-Ziv style data compression algorithm using Finite State Entropy coding.
      It targets similar compression rates at higher compression and decompression speed compared to deflate using zlib.
    '';
    platforms = platforms.unix;
    license = licenses.bsd3;
    maintainers = [ ];
    mainProgram = "lzfse";
  };
}
