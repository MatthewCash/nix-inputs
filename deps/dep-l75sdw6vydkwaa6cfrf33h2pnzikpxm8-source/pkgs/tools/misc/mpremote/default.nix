{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  hatchling,
  hatch-requirements-txt,
  hatch-vcs,
  pyserial,
  importlib-metadata,
}:
buildPythonApplication rec {
  pname = "mpremote";
  version = "1.24.0";

  src = fetchFromGitHub {
    owner = "micropython";
    repo = "micropython";
    tag = "v${version}";
    hash = "sha256-nBz4m5YxD6MV5SyyzvJcwBTttV8uJGdcCUY6HYxZ4nY=";
  };
  sourceRoot = "${src.name}/tools/mpremote";
  format = "pyproject";

  nativeBuildInputs = [
    hatchling
    hatch-requirements-txt
    hatch-vcs
  ];
  propagatedBuildInputs = [
    pyserial
    importlib-metadata
  ];

  pythonImportsCheck = [ "mpremote" ];

  meta = with lib; {
    description = "Integrated set of utilities to remotely interact with and automate a MicroPython device over a serial connection";
    homepage = "https://github.com/micropython/micropython/blob/master/tools/mpremote/README.md";
    platforms = platforms.unix;
    license = licenses.mit;
    maintainers = with maintainers; [ _999eagle ];
    mainProgram = "mpremote";
  };
}
