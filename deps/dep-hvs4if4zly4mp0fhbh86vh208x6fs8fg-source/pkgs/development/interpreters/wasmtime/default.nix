{
  lib,
  rustPlatform,
  cmake,
  rustfmt,
  fetchFromGitHub,
  Security,
  stdenv,
}:

rustPlatform.buildRustPackage rec {
  pname = "wasmtime";
  version = "26.0.1";

  src = fetchFromGitHub {
    owner = "bytecodealliance";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Q7f35Y3ZZ7BHLwmdsa0I5gtlNMObscVD/3jKrVetGnA=";
    fetchSubmodules = true;
  };

  # Disable cargo-auditable until https://github.com/rust-secure-code/cargo-auditable/issues/124 is solved.
  auditable = false;
  cargoHash = "sha256-kaE+LoqnWPZcM9H5FM7SRPRq2J78yrL5zWdV2klVLDU=";
  cargoBuildFlags = [
    "--package"
    "wasmtime-cli"
    "--package"
    "wasmtime-c-api"
  ];

  outputs = [
    "out"
    "dev"
  ];

  buildInputs = lib.optional stdenv.hostPlatform.isDarwin Security;

  # rustfmt is brought into scope to fix the following
  #   warning: cranelift-codegen@0.108.0:
  #   Failed to run `rustfmt` on ISLE-generated code: Os
  #   { code: 2, kind: NotFound, message: "No such file or directory" }
  nativeBuildInputs = [
    cmake
    rustfmt
  ];

  doCheck =
    with stdenv.buildPlatform;
    # SIMD tests are only executed on platforms that support all
    # required processor features (e.g. SSE3, SSSE3 and SSE4.1 on x86_64):
    # https://github.com/bytecodealliance/wasmtime/blob/v9.0.0/cranelift/codegen/src/isa/x64/mod.rs#L220
    (isx86_64 -> sse3Support && ssse3Support && sse4_1Support)
    &&
      # The dependency `wasi-preview1-component-adapter` fails to build because of:
      # error: linker `rust-lld` not found
      !isAarch64;

  postInstall =
    ''
      # move libs from out to dev
      install -d -m 0755 $dev/lib
      install -m 0644 ''${!outputLib}/lib/* $dev/lib
      rm -r ''${!outputLib}/lib

      install -d -m0755 $dev/include/wasmtime
      install -m0644 $src/crates/c-api/include/*.h $dev/include
      install -m0644 $src/crates/c-api/include/wasmtime/*.h $dev/include/wasmtime
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      install_name_tool -id \
        $dev/lib/libwasmtime.dylib \
        $dev/lib/libwasmtime.dylib
    '';

  meta = with lib; {
    description = "Standalone JIT-style runtime for WebAssembly, using Cranelift";
    homepage = "https://wasmtime.dev/";
    license = licenses.asl20;
    mainProgram = "wasmtime";
    maintainers = with maintainers; [
      ereslibre
      matthewbauer
    ];
    platforms = platforms.unix;
    changelog = "https://github.com/bytecodealliance/wasmtime/blob/v${version}/RELEASES.md";
  };
}
