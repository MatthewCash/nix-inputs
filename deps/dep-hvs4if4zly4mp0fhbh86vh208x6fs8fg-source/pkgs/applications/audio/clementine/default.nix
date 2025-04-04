{
  lib,
  mkDerivation,
  fetchFromGitHub,
  boost,
  cmake,
  chromaprint,
  gettext,
  gst_all_1,
  liblastfm,
  qtbase,
  qtx11extras,
  qttools,
  taglib,
  fftw,
  glew,
  qjson,
  sqlite,
  libgpod,
  libplist,
  usbmuxd,
  libmtp,
  libpulseaudio,
  gvfs,
  libcdio,
  pcre,
  projectm,
  protobuf,
  qca-qt5,
  pkg-config,
  sparsehash,
  config,
  makeWrapper,
  gst_plugins,

  util-linux,
  libunwind,
  libselinux,
  elfutils,
  libsepol,
  orc,

  alsa-lib,
}:

let
  withIpod = config.clementine.ipod or false;
  withMTP = config.clementine.mtp or true;
  withCD = config.clementine.cd or true;
  withCloud = config.clementine.cloud or true;
in
mkDerivation {
  pname = "clementine";
  version = "1.4.rc2-unstable-2024-05-12";

  src = fetchFromGitHub {
    owner = "clementine-player";
    repo = "Clementine";
    rev = "7607ddcb96e79d373c4b60d9de21f3315719c7d8";
    sha256 = "sha256-yOG/Je6N8YEsu5AOtxOFgDl3iqb97assYMZYMSwQqqk=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    makeWrapper

    util-linux
    libunwind
    libselinux
    elfutils
    libsepol
    orc
  ];

  buildInputs =
    [
      boost
      chromaprint
      fftw
      gettext
      glew
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-bad
      gst_all_1.gstreamer
      gvfs
      liblastfm
      libpulseaudio
      pcre
      projectm
      protobuf
      qca-qt5
      qjson
      qtbase
      qtx11extras
      qttools
      sqlite
      taglib

      alsa-lib
    ]
    # gst_plugins needed for setup-hooks
    ++ gst_plugins
    ++ lib.optionals (withIpod) [
      libgpod
      libplist
      usbmuxd
    ]
    ++ lib.optionals (withMTP) [ libmtp ]
    ++ lib.optionals (withCD) [ libcdio ]
    ++ lib.optionals (withCloud) [ sparsehash ];

  postPatch = ''
    sed -i src/CMakeLists.txt \
      -e 's,-Werror,,g' \
      -e 's,-Wno-unknown-warning-option,,g' \
      -e 's,-Wno-unused-private-field,,g'
    sed -i CMakeLists.txt \
      -e 's,libprotobuf.a,protobuf,g'
  '';

  preConfigure = ''
    rm -rf ext/{,lib}clementine-spotifyblob
  '';

  cmakeFlags = [
    "-DFORCE_GIT_REVISION=1.3.1"
    "-DUSE_SYSTEM_PROJECTM=ON"
    "-DSPOTIFY_BLOB=OFF"
  ];

  postInstall = ''
    wrapProgram $out/bin/clementine \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0"
  '';

  meta = with lib; {
    homepage = "https://www.clementine-player.org";
    description = "Multiplatform music player";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.ttuegel ];
  };
}
