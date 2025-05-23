{
  lib,
  rustPlatform,
  fetchFromGitHub,
  cmake,
  pkg-config,
  stdenv,
  apple-sdk_11,
  curl,
  openssl,
  buildPackages,
  installShellFiles,
}:

let
  canRunCmd = stdenv.hostPlatform.emulatorAvailable buildPackages;
  gix = "${stdenv.hostPlatform.emulator buildPackages} $out/bin/gix";
  ein = "${stdenv.hostPlatform.emulator buildPackages} $out/bin/ein";
in
rustPlatform.buildRustPackage rec {
  pname = "gitoxide";
  version = "0.38.0";

  src = fetchFromGitHub {
    owner = "Byron";
    repo = "gitoxide";
    rev = "v${version}";
    hash = "sha256-JqWFdZXcmL97w5CochG9kXXH7cN2KMarkNUvfQXbYU0=";
  };

  cargoHash = "sha256-EGPx4NNvgGe+LJ8Gn0ne8O4lCA+9p+E9J7OOhLQDWX0=";

  nativeBuildInputs = [
    cmake
    pkg-config
    installShellFiles
  ];

  buildInputs = [ curl ] ++ (if stdenv.hostPlatform.isDarwin then [ apple-sdk_11 ] else [ openssl ]);

  preFixup = lib.optionalString canRunCmd ''
    installShellCompletion --cmd gix \
      --bash <(${gix} completions --shell bash) \
      --fish <(${gix} completions --shell fish) \
      --zsh <(${gix} completions --shell zsh)

    installShellCompletion --cmd ein \
      --bash <(${ein} completions --shell bash) \
      --fish <(${ein} completions --shell fish) \
      --zsh <(${ein} completions --shell zsh)
  '';

  # Needed to get openssl-sys to use pkg-config.
  env.OPENSSL_NO_VENDOR = 1;

  meta = with lib; {
    description = "Command-line application for interacting with git repositories";
    homepage = "https://github.com/Byron/gitoxide";
    changelog = "https://github.com/Byron/gitoxide/blob/v${version}/CHANGELOG.md";
    license = with licenses; [
      mit # or
      asl20
    ];
    maintainers = with maintainers; [ syberant ];
    knownVulnerabilities = [
      "CVE-2025-31130 / GHSA-2frx-2596-x5r6 – consider using gitoxide from 25.05/unstable"
    ];
  };
}
