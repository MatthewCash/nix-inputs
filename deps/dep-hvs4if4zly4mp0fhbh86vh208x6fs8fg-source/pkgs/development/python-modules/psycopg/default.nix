{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  fetchurl,
  pythonOlder,
  substituteAll,

  # build
  postgresql,
  setuptools,

  # propagates
  backports-zoneinfo,
  typing-extensions,

  # psycopg-c
  cython,
  tomli,

  # docs
  furo,
  shapely,
  sphinxHook,
  sphinx-autodoc-typehints,

  # tests
  anyio,
  pproxy,
  pytest-randomly,
  pytestCheckHook,
  postgresqlTestHook,
}:

let
  pname = "psycopg";
  version = "3.2.3";

  src = fetchFromGitHub {
    owner = "psycopg";
    repo = pname;
    tag = version;
    hash = "sha256-vcUZvQeD5MnEM02phk73I9dpf0Eug95V7Rspi0s6S2M=";
  };

  patches = [
    (substituteAll {
      src = ./ctypes.patch;
      libpq = "${postgresql.lib}/lib/libpq${stdenv.hostPlatform.extensions.sharedLibrary}";
      libc = "${stdenv.cc.libc}/lib/libc.so.6";
    })
  ];

  baseMeta = {
    changelog = "https://github.com/psycopg/psycopg/blob/${version}/docs/news.rst#current-release";
    homepage = "https://github.com/psycopg/psycopg";
    license = lib.licenses.lgpl3Plus;
    maintainers = with lib.maintainers; [ hexa ];
  };

  psycopg-c = buildPythonPackage {
    pname = "${pname}-c";
    inherit version src;
    format = "pyproject";

    # apply patches to base repo
    inherit patches;

    # move into source root after patching
    postPatch = ''
      cd psycopg_c
    '';

    nativeBuildInputs = [
      cython
      # needed to find pg_config with strictDeps
      postgresql
      setuptools
      tomli
    ];

    buildInputs = [
      postgresql
    ];

    # tested in psycopg
    doCheck = false;

    meta = baseMeta // {
      description = "C optimisation distribution for Psycopg";
    };
  };

  psycopg-pool = buildPythonPackage {
    pname = "${pname}-pool";
    inherit version src;
    format = "setuptools";

    # apply patches to base repo
    inherit patches;

    # move into source root after patching
    postPatch = ''
      cd psycopg_pool
    '';

    propagatedBuildInputs = [ typing-extensions ];

    # tested in psycopg
    doCheck = false;

    meta = baseMeta // {
      description = "Connection Pool for Psycopg";
    };
  };
in

buildPythonPackage rec {
  inherit pname version src;
  format = "pyproject";

  disabled = pythonOlder "3.7";

  outputs = [
    "out"
    "doc"
  ];

  sphinxRoot = "../docs";

  # Introduce this file necessary for the docs build via environment var
  LIBPQ_DOCS_FILE = fetchurl {
    url = "https://raw.githubusercontent.com/postgres/postgres/496a1dc44bf1261053da9b3f7e430769754298b4/doc/src/sgml/libpq.sgml";
    hash = "sha256-JwtCngkoi9pb0pqIdNgukY8GbG5pUDZvrGAHZqjFOw4";
  };

  inherit patches;

  # only move to sourceRoot after patching, makes patching easier
  postPatch = ''
    cd psycopg
  '';

  nativeBuildInputs = [
    furo
    setuptools
    shapely
    sphinx-autodoc-typehints
    sphinxHook
  ];

  propagatedBuildInputs = [
    psycopg-c
    typing-extensions
  ] ++ lib.optionals (pythonOlder "3.9") [ backports-zoneinfo ];

  pythonImportsCheck = [
    "psycopg"
    "psycopg_c"
    "psycopg_pool"
  ];

  optional-dependencies = {
    c = [ psycopg-c ];
    pool = [ psycopg-pool ];
  };

  nativeCheckInputs =
    [
      anyio
      pproxy
      pytest-randomly
      pytestCheckHook
      postgresql
    ]
    ++ lib.optional (stdenv.hostPlatform.isLinux) postgresqlTestHook
    ++ optional-dependencies.c
    ++ optional-dependencies.pool;

  env = {
    postgresqlEnableTCP = 1;
    PGUSER = "psycopg";
    PGDATABASE = "psycopg";
  };

  preCheck =
    ''
      cd ..
    ''
    + lib.optionalString (stdenv.hostPlatform.isLinux) ''
      export PSYCOPG_TEST_DSN="host=/build/run/postgresql user=$PGUSER"
    '';

  disabledTests = [
    # don't depend on mypy for tests
    "test_version"
    "test_package_version"
  ];

  disabledTestPaths = [
    # Network access
    "tests/test_dns.py"
    "tests/test_dns_srv.py"
    # Mypy typing test
    "tests/test_typing.py"
    "tests/crdb/test_typing.py"
    # https://github.com/psycopg/psycopg/pull/915
    "tests/test_notify.py"
    "tests/test_notify_async.py"
  ];

  pytestFlagsArray = [
    "-o"
    "cache_dir=$TMPDIR"
    "-m"
    "'not refcount and not timing and not flakey'"
    # pytest.PytestRemovedIn9Warning: Marks applied to fixtures have no effect
    "-W"
    "ignore::pytest.PytestRemovedIn9Warning"
  ];

  postCheck = ''
    cd ${pname}
  '';

  passthru = {
    c = psycopg-c;
    pool = psycopg-pool;
  };

  meta = baseMeta // {
    description = "PostgreSQL database adapter for Python";
  };
}
