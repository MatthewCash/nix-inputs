{
  lib,
  callPackage,
  fetchFromGitHub,
  rustPlatform,
  cmake,
  pkg-config,
  protobuf,
  elfutils,
}:

rustPlatform.buildRustPackage rec {
  pname = "router";
  version = "1.56.0";

  src = fetchFromGitHub {
    owner = "apollographql";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-4l9nTbtF8hy2x1fdRhmMKcYxTD6wWKXIfihLTWdtm7U=";
  };

  cargoHash = "sha256-zeMUw/OLPXM1uARrUeva90DLgpD5qFDhVKWgP/c3w7g=";

  nativeBuildInputs = [
    cmake
    pkg-config
    protobuf
  ];

  buildInputs = [
    elfutils
  ];

  # The v8 package will try to download a `librusty_v8.a` release at build time to our read-only filesystem
  # To avoid this we pre-download the file and export it via RUSTY_V8_ARCHIVE
  RUSTY_V8_ARCHIVE = callPackage ./librusty_v8.nix { };

  cargoTestFlags = [
    "-- --skip=query_planner::tests::missing_typename_and_fragments_in_requires"
  ];

  meta = with lib; {
    description = "Configurable, high-performance routing runtime for Apollo Federation";
    homepage = "https://www.apollographql.com/docs/router/";
    license = licenses.elastic20;
    maintainers = [ maintainers.bbigras ];
  };
}
