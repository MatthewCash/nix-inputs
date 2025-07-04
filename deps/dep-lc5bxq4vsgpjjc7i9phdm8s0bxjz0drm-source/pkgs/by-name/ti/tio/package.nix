{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  glib,
  inih,
  lua,
  bash-completion,
  darwin,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tio";
  version = "3.7";

  src = fetchFromGitHub {
    owner = "tio";
    repo = "tio";
    rev = "v${finalAttrs.version}";
    hash = "sha256-/eXy1roYmeZaQlY4PjBchwRR7JwyTvVIqDmmf6upJqA=";
  };

  strictDeps = true;

  buildInputs = [
    inih
    lua
    glib
    bash-completion
  ] ++ lib.optionals (stdenv.hostPlatform.isDarwin) [ darwin.apple_sdk.frameworks.IOKit ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  meta = with lib; {
    description = "Serial console TTY";
    homepage = "https://tio.github.io/";
    license = licenses.gpl2Plus;
    maintainers = [ ];
    mainProgram = "tio";
    platforms = platforms.unix;
  };
})
