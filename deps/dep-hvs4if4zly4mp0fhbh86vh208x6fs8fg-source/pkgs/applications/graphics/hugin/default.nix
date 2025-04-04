{
  lib,
  stdenv,
  cmake,
  fetchurl,
  gnumake,
  makeWrapper,
  pkg-config,
  autopanosiftc,
  boost,
  cairo,
  enblend-enfuse,
  exiv2,
  fftw,
  flann,
  gettext,
  glew,
  ilmbase,
  lcms2,
  lensfun,
  libjpeg,
  libpng,
  libtiff,
  libX11,
  libXi,
  libXmu,
  libGLU,
  libGL,
  openexr_3,
  panotools,
  perlPackages,
  sqlite,
  vigra,
  wrapGAppsHook3,
  wxGTK,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "hugin";
  version = "2023.0.0";

  src = fetchurl {
    url = "mirror://sourceforge/hugin/hugin-${version}.tar.bz2";
    hash = "sha256-BKOfzMYBfgVExjm9IjCUcsV001s0Vcut4fw4cOYxYys=";
  };

  buildInputs = [
    boost
    cairo
    exiv2
    fftw
    flann
    gettext
    glew
    ilmbase
    lcms2
    lensfun
    libjpeg
    libpng
    libtiff
    libX11
    libXi
    libXmu
    libGLU
    libGL
    openexr_3
    panotools
    sqlite
    vigra
    wxGTK
    zlib
  ];

  nativeBuildInputs = [
    cmake
    makeWrapper
    pkg-config
    wrapGAppsHook3
  ];

  # disable installation of the python scripting interface
  cmakeFlags = [ "-DBUILD_HSI:BOOl=OFF" ];

  env.NIX_CFLAGS_COMPILE = "-I${ilmbase.dev}/include/OpenEXR";

  postInstall = ''
    for p in $out/bin/*; do
      wrapProgram "$p" \
        --suffix PATH : ${autopanosiftc}/bin \
        --suffix PATH : ${enblend-enfuse}/bin \
        --suffix PATH : ${gnumake}/bin \
        --suffix PATH : ${perlPackages.ImageExifTool}/bin
    done
  '';

  meta = with lib; {
    homepage = "http://hugin.sourceforge.net/";
    description = "Toolkit for stitching photographs and assembling panoramas, together with an easy to use graphical front end";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ hrdinka ];
    platforms = platforms.linux;
  };
}
