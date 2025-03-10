{
  lib,
  buildPythonPackage,
  cython,
  fetchFromGitHub,
  msgpack,
  pytestCheckHook,
  pythonOlder,
  pyyaml,
  ruamel-yaml,
  setuptools,
  toml,
  tomli,
  tomli-w,
}:

buildPythonPackage rec {
  pname = "python-box";
  version = "7.2.0";
  format = "setuptools";

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "cdgriffith";
    repo = "Box";
    tag = version;
    hash = "sha256-5aORpuh0ezA3mUEpAPANDkdeN8ujNRfCUCV5qamMk68=";
  };

  nativeBuildInputs = [
    cython
    setuptools
  ];

  optional-dependencies = {
    all = [
      msgpack
      ruamel-yaml
      toml
    ];
    yaml = [ ruamel-yaml ];
    ruamel-yaml = [ ruamel-yaml ];
    PyYAML = [ pyyaml ];
    tomli = [ tomli-w ] ++ lib.optionals (pythonOlder "3.11") [ tomli ];
    toml = [ toml ];
    msgpack = [ msgpack ];
  };

  nativeCheckInputs = [ pytestCheckHook ] ++ optional-dependencies.all;

  pythonImportsCheck = [ "box" ];

  meta = with lib; {
    description = "Python dictionaries with advanced dot notation access";
    homepage = "https://github.com/cdgriffith/Box";
    changelog = "https://github.com/cdgriffith/Box/blob/${version}/CHANGES.rst";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ fab ];
  };
}
