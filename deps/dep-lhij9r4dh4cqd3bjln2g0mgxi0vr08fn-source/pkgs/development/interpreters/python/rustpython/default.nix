{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  SystemConfiguration,
  python3,
}:

rustPlatform.buildRustPackage rec {
  pname = "rustpython";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "RustPython";
    repo = "RustPython";
    tag = version;
    hash = "sha256-BYYqvPJu/eFJ9lt07A0p7pd8pGFccUe/okFqGEObhY4=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "rustpython-doc-0.3.0" = "sha256-34ERuLFKzUD9Xmf1zlafe42GLWZfUlw17ejf/NN6yH4=";
    };
  };

  # freeze the stdlib into the rustpython binary
  cargoBuildFlags = [ "--features=freeze-stdlib" ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ SystemConfiguration ];

  nativeCheckInputs = [ python3 ];

  meta = with lib; {
    description = "Python 3 interpreter in written Rust";
    homepage = "https://rustpython.github.io";
    license = licenses.mit;
    maintainers = with maintainers; [ prusnak ];
    #   = note: Undefined symbols for architecture x86_64:
    #       "_utimensat", referenced from:
    #           rustpython_vm::function::builtin::IntoPyNativeFn::into_func::... in
    #           rustpython-10386d81555652a7.rustpython_vm-f0b5bedfcf056d0b.rustpython_vm.7926b68e665728ca-cgu.08.rcgu.o.rcgu.o
    broken = stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isx86_64;
  };
}
