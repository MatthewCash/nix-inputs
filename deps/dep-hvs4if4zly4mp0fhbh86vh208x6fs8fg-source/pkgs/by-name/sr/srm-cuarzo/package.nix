{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  libdisplay-info,
  libdrm,
  libGL,
  libinput,
  mesa,
  seatd,
  udev,
}:
stdenv.mkDerivation (self: {
  pname = "srm-cuarzo";
  version = "0.8.0-1";
  rev = "v${self.version}";
  hash = "sha256-QQYn7TR2+6nZHOohjqEg6uMt4OBvfYD4+bFiDIaC7SU=";

  src = fetchFromGitHub {
    inherit (self) rev hash;
    owner = "CuarzoSoftware";
    repo = "SRM";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    libdisplay-info
    libdrm
    libGL
    libinput
    mesa
    seatd
    udev
  ];

  outputs = [
    "out"
    "dev"
  ];

  preConfigure = ''
    # The root meson.build file is in src/
    cd src
  '';

  meta = {
    description = "Simple Rendering Manager";
    homepage = "https://github.com/CuarzoSoftware/SRM";
    maintainers = [ lib.maintainers.dblsaiko ];
    platforms = lib.platforms.linux;
  };
})
