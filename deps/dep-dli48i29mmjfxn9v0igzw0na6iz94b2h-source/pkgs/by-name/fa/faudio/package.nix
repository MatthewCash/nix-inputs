{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  SDL2,
}:

#TODO: tests

stdenv.mkDerivation rec {
  pname = "faudio";
  version = "24.11";

  src = fetchFromGitHub {
    owner = "FNA-XNA";
    repo = "FAudio";
    rev = version;
    sha256 = "sha256-fmJh2DZNAjqqTDFt5b2HZ5oeS7VkvPy1a8gr59OQSUo=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ SDL2 ];

  meta = with lib; {
    description = "XAudio reimplementation focusing to develop a fully accurate DirectX audio library";
    homepage = "https://github.com/FNA-XNA/FAudio";
    changelog = "https://github.com/FNA-XNA/FAudio/releases/tag/${version}";
    license = licenses.zlib;
    platforms = platforms.unix;
    maintainers = [ maintainers.marius851000 ];
  };
}
