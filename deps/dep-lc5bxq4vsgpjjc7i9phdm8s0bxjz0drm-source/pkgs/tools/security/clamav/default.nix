{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  cmake,
  zlib,
  bzip2,
  libiconv,
  libxml2,
  openssl,
  ncurses,
  curl,
  libmilter,
  pcre2,
  libmspack,
  systemd,
  Foundation,
  json_c,
  check,
  rustc,
  rust-bindgen,
  rustfmt,
  cargo,
  python3,
}:

stdenv.mkDerivation rec {
  pname = "clamav";
  version = "1.4.3";

  src = fetchurl {
    url = "https://www.clamav.net/downloads/production/${pname}-${version}.tar.gz";
    hash = "sha256-2HTKvz1HZbNbUY71NWWKHm7HSAIAah1hP58SSqE0MhA=";
  };

  patches = [
    # Flaky test, remove this when https://github.com/Cisco-Talos/clamav/issues/343 is fixed
    ./remove-freshclam-test.patch
    ./sample-cofiguration-file-install-location.patch
  ];

  enableParallelBuilding = true;
  nativeBuildInputs = [
    cmake
    pkg-config
    rustc
    rust-bindgen
    rustfmt
    cargo
    python3
  ];
  buildInputs =
    [
      zlib
      bzip2
      libxml2
      openssl
      ncurses
      curl
      libiconv
      libmilter
      pcre2
      libmspack
      json_c
      check
    ]
    ++ lib.optional stdenv.hostPlatform.isLinux systemd
    ++ lib.optional stdenv.hostPlatform.isDarwin Foundation;

  cmakeFlags = [
    "-DSYSTEMD_UNIT_DIR=${placeholder "out"}/lib/systemd"
    "-DAPP_CONFIG_DIRECTORY=/etc/clamav"
  ];

  doCheck = true;

  checkInputs = [
    python3.pkgs.pytest
  ];

  meta = with lib; {
    homepage = "https://www.clamav.net";
    description = "Antivirus engine designed for detecting Trojans, viruses, malware and other malicious threats";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [
      robberer
      qknight
      globin
    ];
    platforms = platforms.unix;
  };
}
