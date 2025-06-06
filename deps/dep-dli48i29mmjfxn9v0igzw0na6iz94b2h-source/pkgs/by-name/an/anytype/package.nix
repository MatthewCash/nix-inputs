{
  lib,
  fetchurl,
  appimageTools,
  makeWrapper,
  commandLineArgs ? "",
}:

let
  pname = "anytype";
  version = "0.43.4";
  name = "Anytype-${version}";
  src = fetchurl {
    url = "https://github.com/anyproto/anytype-ts/releases/download/v${version}/${name}.AppImage";
    hash = "sha256-2/+bLRx+iVTBDAH599+TpLquq/z/2FFJ5i6Mz8u4HuM=";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  extraPkgs = pkgs: [ pkgs.libsecret ];

  extraInstallCommands = ''
    wrapProgram $out/bin/${pname} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
      --add-flags ${lib.escapeShellArg commandLineArgs}
    install -m 444 -D ${appimageContents}/anytype.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/anytype.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
    for size in 16 32 64 128 256 512 1024; do
      install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/anytype.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/anytype.png
    done
  '';

  meta = with lib; {
    description = "P2P note-taking tool";
    homepage = "https://anytype.io/";
    license = licenses.unfree;
    mainProgram = "anytype";
    maintainers = with maintainers; [ running-grass ];
    platforms = [ "x86_64-linux" ];
  };
}
