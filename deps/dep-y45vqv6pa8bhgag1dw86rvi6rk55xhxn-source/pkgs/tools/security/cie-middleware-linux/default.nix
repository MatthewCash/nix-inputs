{ stdenv
, lib
, fetchFromGitHub
, fetchpatch
, makeWrapper
, strip-nondeterminism
, meson
, ninja
, pkg-config
, gradle_7
, curl
, cryptopp
, fontconfig
, jre
, libxml2
, openssl
, pcsclite
, podofo
, ghostscript
}:

let
  pname = "cie-middleware-linux";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "M0rf30";
    repo = pname;
    rev = version;
    sha256 = "sha256-Z8K2Ibg5bBfSql5HEapKgdfiCf/EIKTTD15oVeysQGk=";
  };

  gradle = gradle_7;

  # Shared libraries needed by the Java application
  libraries = lib.makeLibraryPath [ ghostscript ];

  # Fixed-output derivation that fetches the Java dependencies
  javaDeps = stdenv.mkDerivation {
    pname = "cie-java-deps";
    inherit src version;

    nativeBuildInputs = [ gradle ];

    buildPhase = ''
      # Run the fetchDeps task
      export GRADLE_USER_HOME=$(mktemp -d)
      ls -l
      gradle --no-daemon -b cie-java/build.gradle fetchDeps
    '';

    installPhase = ''
      # Build a tree compatible with the maven repository format
      pushd "$GRADLE_USER_HOME/caches/modules-2/files-2.1"
      find -type f | awk -F/ -v OFS=/ -v out="$out" '{
        infile = $0
        gsub(/\./, "/", $2)
        system("install -m644 -D "infile" "out"/"$2"/"$3"/"$4"/"$6)
      }'
      popd
    '';

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-jtaH8dBpnx8KMJe+jzJfkvcx1NO4nL5jsRO4+GI+d0c=";
  };

in

stdenv.mkDerivation {
  inherit pname src version;

  hardeningDisable = [ "format" ];

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    makeWrapper
    meson
    ninja
    pkg-config
    gradle
    strip-nondeterminism
  ];

  buildInputs = [
    cryptopp
    fontconfig
    podofo.dev
    openssl
    pcsclite
    curl
    libxml2
  ];

  patches = [
    # Fix gcc-13 build by adding missing include.
    (fetchpatch {
      name = "gcc-13.patch";
      url = "https://github.com/M0Rf30/cie-middleware-linux/commit/1da1196152f7a3bbe92ba3ce993ebb6785ff049e.patch";
      hash = "sha256-aM23A1ZX8kebgX6RXVS78SEa+to93glUmIYO+lfUzfg=";
    })
  ];

  postPatch = ''
    # substitute the cieid command with this $out/bin/cieid
    substituteInPlace libs/pkcs11/src/CSP/AbilitaCIE.cpp \
      --replace 'file = "cieid"' 'file = "'$out'/bin/cieid"'

    # revert https://github.com/M0Rf30/cie-middleware-linux/commit/1a389d8
    sed -i libs/meson.build \
        -e "s@podofo_dep = .\+@podofo_dep = dependency('libpodofo')@g"
  '';

  # Note: we use pushd/popd to juggle between the
  # libraries and the Java application builds.
  preConfigure = "pushd libs";

  postBuild = ''
    popd

    # Use the packages in javaDeps for both plugins and dependencies
    localRepo="maven { url uri('${javaDeps}') }"
    sed -i cie-java/settings.gradle -e "1i \
      pluginManagement { repositories { $localRepo } }"
    substituteInPlace cie-java/build.gradle \
      --replace 'mavenCentral()' "$localRepo"

    # Build the Java application
    export GRADLE_USER_HOME=$(mktemp -d)
    gradle standalone \
      --no-daemon \
      --offline \
      --parallel \
      --info -Dorg.gradle.java.home=${jre} \
      --build-file cie-java/build.gradle

    pushd libs/build
  '';

  postInstall = ''
    popd

    # Install the Java application
    install -Dm755 cie-java/build/libs/CIEID-standalone.jar \
                   "$out/share/cieid/cieid.jar"

    # Create a wrapper
    mkdir -p "$out/bin"
    makeWrapper "${jre}/bin/java" "$out/bin/cieid" \
      --add-flags "-Djna.library.path='$out/lib:${libraries}'" \
      --add-flags '-Dawt.useSystemAAFontSettings=on' \
      --add-flags "-cp $out/share/cieid/cieid.jar" \
      --add-flags "it.ipzs.cieid.MainApplication"

    # Install other files
    install -Dm644 data/cieid.desktop "$out/share/applications/cieid.desktop"
    install -Dm755 data/logo.png "$out/share/pixmaps/cieid.png"
    install -Dm644 LICENSE "$out/share/licenses/cieid/LICENSE"
  '';

  postFixup = ''
    # Move static libraries to the dev output
    mv -t "$dev/lib" "$out/lib/"*.a

    # Make the jar deterministic (mainly, sorting its files)
    strip-nondeterminism "$out/share/cieid/cieid.jar"
  '';

  passthru = { inherit javaDeps; };

  meta = with lib; {
    homepage = "https://github.com/M0Rf30/cie-middleware-linux";
    description = "Middleware for the Italian Electronic Identity Card (CIE)";
    longDescription = ''
      Software for the usage of the Italian Electronic Identity Card (CIE).
      Access to PA services, signing and verification of documents

      Warning: this is an unofficial fork because the original software, as
      distributed by the Italian government, is essentially lacking a build
      system and is in violation of the license of the PoDoFo library.
    '';
    license = licenses.bsd3;
    platforms = platforms.unix;
    # Note: fails due to a lot of broken type conversions
    badPlatforms = platforms.darwin;
    maintainers = with maintainers; [ rnhmjoj ];
  };
}
