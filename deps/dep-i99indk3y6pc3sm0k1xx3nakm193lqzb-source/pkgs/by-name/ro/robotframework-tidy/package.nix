{
  lib,
  python3,
  fetchFromGitHub,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "robotframework-tidy";
  version = "4.15.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "MarketSquare";
    repo = "robotframework-tidy";
    tag = version;
    hash = "sha256-PNf0K1+kjijvJ53UCKkC2LyjBJOroDPdtYjcXbRU1VI=";
  };

  build-system = with python3.pkgs; [ setuptools ];

  dependencies = with python3.pkgs; [
    robotframework
    click
    colorama
    pathspec
    tomli
    rich-click
    jinja2
    tomli-w
  ];

  nativeCheckInputs = with python3.pkgs; [ pytestCheckHook ];

  meta = with lib; {
    description = "Code autoformatter for Robot Framework";
    homepage = "https://robotidy.readthedocs.io";
    changelog = "https://github.com/MarketSquare/robotframework-tidy/blob/main/docs/releasenotes/${version}.rst";
    license = licenses.asl20;
    maintainers = with maintainers; [ otavio ];
    mainProgram = "robotidy";
  };
}
