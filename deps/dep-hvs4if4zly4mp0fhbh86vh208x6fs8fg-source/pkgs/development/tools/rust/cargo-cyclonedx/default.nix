{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  Security,
  SystemConfiguration,
  CoreFoundation,
  curl,
}:

rustPlatform.buildRustPackage rec {
  pname = "cargo-cyclonedx";
  version = "0.5.5";

  src = fetchFromGitHub {
    owner = "CycloneDX";
    repo = "cyclonedx-rust-cargo";
    rev = "${pname}-${version}";
    hash = "sha256-DOnf2O0ezQ6rR83lSG9mtvxXFz2hpxb8qi7xLvVKkYw=";
  };

  cargoHash = "sha256-UHdugnKZ43qYpbaM+orPy7g09ZIcpCvhSMkptmmAf7s=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs =
    [
      openssl
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      Security
      SystemConfiguration
      CoreFoundation
      curl
    ];

  meta = with lib; {
    description = "Creates CycloneDX Software Bill of Materials (SBOM) from Rust (Cargo) projects";
    mainProgram = "cargo-cyclonedx";
    longDescription = ''
      The CycloneDX module for Rust (Cargo) creates a valid CycloneDX Software
      Bill-of-Material (SBOM) containing an aggregate of all project
      dependencies. CycloneDX is a lightweight SBOM specification that is
      easily created, human and machine readable, and simple to parse.
    '';
    homepage = "https://github.com/CycloneDX/cyclonedx-rust-cargo";
    license = licenses.asl20;
    maintainers = with maintainers; [ nikstur ];
  };
}
