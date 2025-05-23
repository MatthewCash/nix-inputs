{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  pythonOlder,
  cryptography,
  jinja2,
  mako,
  passlib,
  pyyaml,
  requests,
  rtoml,
  setuptools,
  tomlkit,
  librouteros,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "bundlewrap";
  version = "4.20.0";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "bundlewrap";
    repo = "bundlewrap";
    tag = version;
    hash = "sha256-GoMOEPZb7efFoZn7D2y1XO4XtP9z+1EmakLvSxcCT8I=";
  };

  build-system = [ setuptools ];
  dependencies = [
    setuptools
    cryptography
    jinja2
    mako
    passlib
    pyyaml
    requests
    tomlkit
    librouteros
  ] ++ lib.optionals (pythonOlder "3.11") [ rtoml ];

  pythonImportsCheck = [ "bundlewrap" ];

  nativeCheckInputs = [ pytestCheckHook ];

  pytestFlagsArray = [
    # only unit tests as integration tests need a OpenSSH client/server setup
    "tests/unit"
  ];

  meta = with lib; {
    homepage = "https://bundlewrap.org/";
    description = "Easy, Concise and Decentralized Config management with Python";
    mainProgram = "bw";
    license = [ licenses.gpl3 ];
    maintainers = with maintainers; [ wamserma ];
  };
}
