{
  lib,
  stdenv,
  fetchFromGitHub,
  libedit,
  autoreconfHook271,
  zlib,
  unzip,
  libtommath,
  libtomcrypt,
  icu,
  superServer ? false,
}:

let
  base = {
    pname = "firebird";

    meta = with lib; {
      description = "SQL relational database management system";
      downloadPage = "https://github.com/FirebirdSQL/firebird/";
      homepage = "https://firebirdsql.org/";
      changelog = "https://github.com/FirebirdSQL/firebird/blob/master/CHANGELOG.md";
      license = [
        "IDPL"
        "Interbase-1.0"
      ];
      platforms = platforms.linux;
      maintainers = with maintainers; [ marcweber ];
    };

    nativeBuildInputs = [ autoreconfHook271 ];

    buildInputs = [
      libedit
      icu
    ];

    LD_LIBRARY_PATH = lib.makeLibraryPath [ icu ];

    configureFlags = [
      "--with-system-editline"
    ] ++ (lib.optional superServer "--enable-superserver");

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r gen/Release/firebird/* $out
      runHook postInstall
    '';

  };
in
rec {

  firebird_2_5 = stdenv.mkDerivation (
    base
    // rec {
      version = "2.5.9";

      src = fetchFromGitHub {
        owner = "FirebirdSQL";
        repo = "firebird";
        rev = "R${builtins.replaceStrings [ "." ] [ "_" ] version}";
        sha256 = "sha256-YyvlMeBux80OpVhsCv+6IVxKXFRsgdr+1siupMR13JM=";
      };

      configureFlags = base.configureFlags ++ [ "--with-system-icu" ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r gen/firebird/* $out
        runHook postInstall
      '';

      meta = base.meta // {
        platforms = [ "x86_64-linux" ];
      };
    }
  );

  firebird_3 = stdenv.mkDerivation (
    base
    // rec {
      version = "3.0.10";

      src = fetchFromGitHub {
        owner = "FirebirdSQL";
        repo = "firebird";
        rev = "v${version}";
        sha256 = "sha256-PT2b3989n/7xLGNREWinEey9SGnAXShITdum+yiFlHY=";
      };

      buildInputs = base.buildInputs ++ [
        zlib
        libtommath
      ];

      meta = base.meta // {
        platforms = [ "x86_64-linux" ];
      };
    }
  );

  firebird_4 = stdenv.mkDerivation (
    base
    // rec {
      version = "4.0.2";

      src = fetchFromGitHub {
        owner = "FirebirdSQL";
        repo = "firebird";
        rev = "v${version}";
        sha256 = "sha256-hddW/cozboGw693q4k5f4+x9ccQFWFytXPUaBVkFnL4=";
      };

      buildInputs = base.buildInputs ++ [
        zlib
        unzip
        libtommath
        libtomcrypt
      ];
    }
  );

  firebird = firebird_4;
}
