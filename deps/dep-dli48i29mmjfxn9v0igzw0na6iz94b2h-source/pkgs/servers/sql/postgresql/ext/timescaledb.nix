{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  postgresql,
  openssl,
  libkrb5,
  nixosTests,
  enableUnfree ? true,
  buildPostgresqlExtension,
}:

buildPostgresqlExtension rec {
  pname = "timescaledb${lib.optionalString (!enableUnfree) "-apache"}";
  version = "2.14.2";

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    openssl
    libkrb5
  ];

  src = fetchFromGitHub {
    owner = "timescale";
    repo = "timescaledb";
    rev = version;
    hash = "sha256-gJViEWHtIczvIiQKuvvuwCfWJMxAYoBhCHhD75no6r0=";
  };

  cmakeFlags =
    [
      "-DSEND_TELEMETRY_DEFAULT=OFF"
      "-DREGRESS_CHECKS=OFF"
      "-DTAP_CHECKS=OFF"
    ]
    ++ lib.optionals (!enableUnfree) [ "-DAPACHE_ONLY=ON" ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ "-DLINTER=OFF" ];

  # Fix the install phase which tries to install into the pgsql extension dir,
  # and cannot be manually overridden. This is rather fragile but works OK.
  postPatch = ''
    for x in CMakeLists.txt sql/CMakeLists.txt; do
      substituteInPlace "$x" \
        --replace-fail 'DESTINATION "''${PG_SHAREDIR}/extension"' "DESTINATION \"$out/share/postgresql/extension\""
    done

    for x in src/CMakeLists.txt src/loader/CMakeLists.txt tsl/src/CMakeLists.txt; do
      substituteInPlace "$x" \
        --replace-fail 'DESTINATION ''${PG_PKGLIBDIR}' "DESTINATION \"$out/lib\""
    done
  '';

  passthru.tests = nixosTests.postgresql.timescaledb.passthru.override postgresql;

  meta = with lib; {
    description = "Scales PostgreSQL for time-series data via automatic partitioning across time and space";
    homepage = "https://www.timescale.com/";
    changelog = "https://github.com/timescale/timescaledb/blob/${version}/CHANGELOG.md";
    maintainers = [ ];
    platforms = postgresql.meta.platforms;
    license = with licenses; if enableUnfree then tsl else asl20;
    broken =
      versionOlder postgresql.version "13"
      ||
        # timescaledb supports PostgreSQL 17 from 2.17.0 on:
        # https://github.com/timescale/timescaledb/releases/tag/2.17.0
        # We can't upgrade to it, yet, because this would imply dropping support for
        # PostgreSQL 13, which is a breaking change.
        (versionAtLeast postgresql.version "17" && version == "2.14.2");
  };
}
