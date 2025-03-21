{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  ffmpeg,
}:

rustPlatform.buildRustPackage rec {
  pname = "gifski";
  version = "1.32.0";

  src = fetchFromGitHub {
    owner = "ImageOptim";
    repo = "gifski";
    rev = version;
    hash = "sha256-Sl8HRc5tfRcYxXsXmvZ3M+f7PU7+1jz+IKWPhWWQ/us=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "ffmpeg-sys-next-6.1.0" = "sha256-RB9sDQoP68Dzqk8tIuYlOX3dZcS64hKI5KpTGq/7xbM=";
    };
  };

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    ffmpeg
  ];

  buildFeatures = [ "video" ];

  # When the default checkType of release is used, we get the following error:
  #
  #   error: the crate `gifski` is compiled with the panic strategy `abort` which
  #   is incompatible with this crate's strategy of `unwind`
  #
  # It looks like https://github.com/rust-lang/cargo/issues/6313, which does not
  # outline a solution.
  #
  checkType = "debug";

  meta = with lib; {
    description = "GIF encoder based on libimagequant (pngquant)";
    homepage = "https://gif.ski/";
    changelog = "https://github.com/ImageOptim/gifski/releases/tag/${src.rev}";
    license = licenses.agpl3Plus;
    maintainers = with maintainers; [ figsoda ];
    mainProgram = "gifski";
  };
}
