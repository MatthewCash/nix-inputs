{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  pdm-backend,
  appdirs,
  loguru,
  requests,
  setuptools,
  toml,
  websocket-client,
  asciimatics,
  pyperclip,
  aria2,
  fastapi,
  psutil,
  pytest-xdist,
  pytestCheckHook,
  responses,
  uvicorn,

  withTui ? true,
}:

buildPythonPackage rec {
  pname = "aria2p";
  version = "0.12.0";
  pyproject = true;

  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "pawamoy";
    repo = pname;
    tag = version;
    hash = "sha256-WlbZP2+qUSyfmeFFiuarXI3VaNZvD9cnOef/WM+J0OE=";
  };

  nativeBuildInputs = [ pdm-backend ];

  propagatedBuildInputs = [
    appdirs
    loguru
    requests
    setuptools # for pkg_resources
    toml
    websocket-client
  ] ++ lib.optionals withTui optional-dependencies.tui;

  optional-dependencies = {
    tui = [
      asciimatics
      pyperclip
    ];
  };

  preCheck = ''
    export HOME=$TMPDIR
  '';

  nativeCheckInputs = [
    aria2
    fastapi
    pytest-xdist
    pytestCheckHook
    responses
    psutil
    uvicorn
  ] ++ optional-dependencies.tui;

  disabledTests = [
    # require a running display server
    "test_add_downloads_torrents_and_metalinks"
    "test_add_downloads_uris"
    # require a running aria2 server
    "test_cli_autoclear_commands"
    "test_get_files_method"
    "test_pause_subcommand"
    "test_resume_method"
  ];

  pythonImportsCheck = [ "aria2p" ];

  meta = {
    homepage = "https://github.com/pawamoy/aria2p";
    changelog = "https://github.com/pawamoy/aria2p/blob/${src.rev}/CHANGELOG.md";
    description = "Command-line tool and library to interact with an aria2c daemon process with JSON-RPC";
    mainProgram = "aria2p";
    license = lib.licenses.isc;
    maintainers = with lib.maintainers; [ koral ];
    badPlatforms = [
      lib.systems.inspect.patterns.isDarwin
    ];
  };
}
