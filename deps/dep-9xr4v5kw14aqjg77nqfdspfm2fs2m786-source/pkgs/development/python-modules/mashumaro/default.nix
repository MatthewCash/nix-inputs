{
  lib,
  buildPythonPackage,
  ciso8601,
  fetchFromGitHub,
  msgpack,
  orjson,
  pendulum,
  pytest-mock,
  pytestCheckHook,
  pythonOlder,
  pyyaml,
  setuptools,
  tomli,
  tomli-w,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "mashumaro";
  version = "3.14";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "Fatal1ty";
    repo = "mashumaro";
    tag = "v${version}";
    hash = "sha256-0THj22KdMvD5O3dNwXKxs2wRIJziPmojLo4BPa3fZ3Y=";
  };

  build-system = [ setuptools ];

  dependencies = [ typing-extensions ];

  optional-dependencies = {
    orjson = [ orjson ];
    msgpack = [ msgpack ];
    yaml = [ pyyaml ];
    toml = [ tomli-w ] ++ lib.optionals (pythonOlder "3.11") [ tomli ];
  };

  nativeCheckInputs = [
    ciso8601
    pendulum
    pytest-mock
    pytestCheckHook
  ] ++ lib.flatten (lib.attrValues optional-dependencies);

  pythonImportsCheck = [ "mashumaro" ];

  meta = with lib; {
    description = "Serialization library on top of dataclasses";
    homepage = "https://github.com/Fatal1ty/mashumaro";
    changelog = "https://github.com/Fatal1ty/mashumaro/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ tjni ];
  };
}
