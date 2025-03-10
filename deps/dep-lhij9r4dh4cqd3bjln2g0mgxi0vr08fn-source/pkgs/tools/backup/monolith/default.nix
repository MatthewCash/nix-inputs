{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  libiconv,
  Security,
  SystemConfiguration,
}:

rustPlatform.buildRustPackage rec {
  pname = "monolith";
  version = "2.8.1";

  src = fetchFromGitHub {
    owner = "Y2Z";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-qMB4Tok0tYAqj8r9LEkjhBV5ko+hwagFS7MsL8AYJnc=";
  };

  cargoHash = "sha256-FeD0+s79orFDUVsb205W0pdXgDI+p1UrH3GIfKwUqDQ=";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ pkg-config ];
  buildInputs =
    lib.optionals stdenv.hostPlatform.isLinux [ openssl ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      libiconv
      Security
      SystemConfiguration
    ];

  checkFlags = [ "--skip=tests::cli" ];

  meta = with lib; {
    description = "Bundle any web page into a single HTML file";
    mainProgram = "monolith";
    homepage = "https://github.com/Y2Z/monolith";
    license = licenses.unlicense;
    maintainers = with maintainers; [ Br1ght0ne ];
  };
}
