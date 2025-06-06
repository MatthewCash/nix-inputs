{
  stdenv,
  lib,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  dbus,
  fontconfig,
  freetype,
  glib,
  gst_all_1,
  libGL,
  libinput,
  libpulseaudio,
  libsecret,
  libtiff,
  libxkbcommon,
  mesa,
  openssl,
  systemd,
  xorg,
}:

stdenv.mkDerivation rec {
  pname = "alfaview";
  version = "9.17.0";

  src = fetchurl {
    url = "https://assets.alfaview.com/stable/linux/deb/${pname}_${version}.deb";
    hash = "sha256-Rq/5QByaqGd5Cfr4r+Ojv8OC8PvFQ4a+TT8CgeevF28=";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    dbus
    fontconfig
    freetype
    glib
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-base
    libGL
    libinput
    libpulseaudio
    libsecret
    libtiff
    libxkbcommon
    mesa
    openssl
    stdenv.cc.cc
    systemd
    xorg.libX11
    xorg.xcbutilwm
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
  ];

  libPath = lib.makeLibraryPath buildInputs;

  dontBuild = true;
  dontConfigure = true;

  unpackPhase = ''
    dpkg-deb -x ${src} ./
  '';

  installPhase = ''
    runHook preInstall

    mv usr $out
    mv opt $out

    substituteInPlace $out/share/applications/alfaview.desktop \
      --replace "/opt/alfaview" "$out/bin" \
      --replace "/usr/share/pixmaps/alfaview_production.png" alfaview_production

    makeWrapper $out/opt/alfaview/alfaview $out/bin/alfaview \
      --prefix LD_LIBRARY_PATH : ${libPath}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Video-conferencing application, specialized in virtual online meetings, seminars, training sessions and conferences";
    homepage = "https://alfaview.com";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    maintainers = [ ];
    mainProgram = "alfaview";
    platforms = [ "x86_64-linux" ];
  };
}
