{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  fetchpatch,
  darwin,
  libiconv,
  testers,
  nix-update-script,
  maturin,
  python3,
}:

rustPlatform.buildRustPackage rec {
  pname = "maturin";
  version = "1.7.5";

  src = fetchFromGitHub {
    owner = "PyO3";
    repo = "maturin";
    rev = "v${version}";
    hash = "sha256-rggMNvvWj6yAczWt0ztNoXvxafERV5jzbXKlVXt+GbU=";
  };

  cargoHash = "sha256-kLTLUkOYQPdFOXyjBoPMT/2IMC2oILK+i/jY0iDjS2o=";

  patches = [
    # Sorts RECORD file in wheel archives to make them deterministic. See: https://github.com/NixOS/nixpkgs/issues/384708
    # Remove on next bump https://github.com/PyO3/maturin/pull/2550
    (fetchpatch {
      name = "wheel-deterministic-record.patch";
      url = "https://github.com/PyO3/maturin/commit/bade37e108514f4288c1dd6457119a257bf95db4.patch";
      hash = "sha256-jcZ/NMHKFYQuOfR+fu5UPykEljUq3l/+ZAx0Tlyu3Zw=";
    })
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.Security
    libiconv
  ];

  # Requires network access, fails in sandbox.
  doCheck = false;

  passthru = {
    tests = {
      version = testers.testVersion { package = maturin; };
      pyo3 = python3.pkgs.callPackage ./pyo3-test {
        format = "pyproject";
        buildAndTestSubdir = "examples/word-count";
        preConfigure = "";

        nativeBuildInputs = with rustPlatform; [
          cargoSetupHook
          maturinBuildHook
        ];
      };
    };

    updateScript = nix-update-script { };
  };

  meta = {
    description = "Build and publish Rust crates Python packages";
    longDescription = ''
      Build and publish Rust crates with PyO3, rust-cpython, and
      cffi bindings as well as Rust binaries as Python packages.

      This project is meant as a zero-configuration replacement for
      setuptools-rust and Milksnake. It supports building wheels for
      Python and can upload them to PyPI.
    '';
    homepage = "https://github.com/PyO3/maturin";
    changelog = "https://github.com/PyO3/maturin/blob/v${version}/Changelog.md";
    license = with lib.licenses; [
      asl20 # or
      mit
    ];
    maintainers = with lib.maintainers; [ getchoo ];
    mainProgram = "maturin";
  };
}
