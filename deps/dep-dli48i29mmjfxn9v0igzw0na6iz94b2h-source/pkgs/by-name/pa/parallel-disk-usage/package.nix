{
  lib,
  stdenv,
  darwin,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "parallel-disk-usage";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "KSXGitHub";
    repo = pname;
    rev = version;
    hash = "sha256-0SK7v5xKMPuukyYKaGk13PE3WygHginjnyoatkA5xFQ=";
  };

  cargoHash = "sha256-T/TjiqBZJINgiuTLWD+JBCUDEQBs2b/hvZn9E2uxkYc=";

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk_11_0.frameworks.IOKit
    darwin.apple_sdk_11_0.frameworks.CoreFoundation
  ];

  meta = with lib; {
    description = "Highly parallelized, blazing fast directory tree analyzer";
    homepage = "https://github.com/KSXGitHub/parallel-disk-usage";
    license = licenses.asl20;
    maintainers = [ maintainers.peret ];
    mainProgram = "pdu";
  };
}
