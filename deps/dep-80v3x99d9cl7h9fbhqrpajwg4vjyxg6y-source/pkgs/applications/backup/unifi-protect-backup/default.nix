{ lib
, fetchFromGitHub
, python3
}:

python3.pkgs.buildPythonApplication rec {
  pname = "unifi-protect-backup";
  version = "0.10.2";

  format = "pyproject";

  src = fetchFromGitHub {
    owner = "ep1cman";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-EQCI7TkkOhDASMo5yKfAca/gB4ayyPOaDVK6WEaAIgc=";
  };

  pythonRelaxDeps = [
    "aiorun"
    "aiosqlite"
    "click"
    "pyunifiprotect"
  ];

  nativeBuildInputs = with python3.pkgs; [
    poetry-core
    pythonRelaxDepsHook
  ];

  propagatedBuildInputs = with python3.pkgs; [
    aiocron
    aiorun
    aiosqlite
    apprise
    async-lru
    click
    expiring-dict
    python-dateutil
    pyunifiprotect
  ];

  nativeCheckInputs = with python3.pkgs; [
    pytestCheckHook
  ];

  meta = with lib; {
    description = "Python tool to backup unifi event clips in realtime";
    homepage = "https://github.com/ep1cman/unifi-protect-backup";
    changelog = "https://github.com/ep1cman/unifi-protect-backup/blob/v${version}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ ajs124 ];
    mainProgram = "unifi-protect-backup";
  };
}