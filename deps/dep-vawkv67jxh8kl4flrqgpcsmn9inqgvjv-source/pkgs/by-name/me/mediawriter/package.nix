{
  lib,
  stdenv,
  adwaita-qt6,
  appstream-glib,
  cmake,
  fetchFromGitHub,
  qt6,
  udisks2,
  xz,
}:

stdenv.mkDerivation rec {
  pname = "mediawriter";
  version = "5.1.90";

  src = fetchFromGitHub {
    owner = "FedoraQt";
    repo = "MediaWriter";
    tag = version;
    hash = "sha256-ClqBEITZU1gx04ouPk4hBuURSRIg1CSYfMBdfnvD51Q=";
  };

  nativeBuildInputs = [
    cmake
    qt6.wrapQtAppsHook
  ];

  propagatedBuildInputs = [
    adwaita-qt6
    appstream-glib
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    udisks2
    xz
  ];

  meta = with lib; {
    description = "Tool to write images files to portable media";
    homepage = "https://github.com/FedoraQt/MediaWriter";
    changelog = "https://github.com/FedoraQt/MediaWriter/releases/tag/${version}";
    license = licenses.lgpl2Only;
    maintainers = with maintainers; [ fab ];
    mainProgram = "mediawriter";
  };
}
