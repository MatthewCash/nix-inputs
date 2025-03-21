{
  rustPlatform,
  lib,
  fetchFromGitHub,
  stdenv,
  darwin,
}:

rustPlatform.buildRustPackage rec {
  pname = "kubetui";
  version = "1.5.4";

  src = fetchFromGitHub {
    owner = "sarub0b0";
    repo = "kubetui";
    tag = "v${version}";
    hash = "sha256-Trgc3T+01u1izePfM0wPjer3IrA6PtIGsK+syEzs0V8=";
  };

  checkFlags = [
    "--skip=workers::kube::store::tests::kubeconfigからstateを生成"
  ];

  buildInputs = lib.optionals (stdenv.isDarwin) (
    with darwin.apple_sdk;
    [
      frameworks.CoreGraphics
      frameworks.AppKit
    ]
  );
  cargoHash = "sha256-f9JrowyZx4NvfGJSU/HjyTfWKhkAANNfUgcK9CRPW7I=";

  meta = {
    homepage = "https://github.com/sarub0b0/kubetui";
    changelog = "https://github.com/sarub0b0/kubetui/releases/tag/v${version}";
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ bot-wxt1221 ];
    license = lib.licenses.mit;
    description = "Intuitive TUI tool for real-time monitoring and exploration of Kubernetes resources";
    mainProgram = "kubetui";
  };
}
