{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pycryptodome,
  pythonOlder,
  requests,
  websocket-client,
  # dependencies for tests
  pytest-cov-stub,
  pytest,
  sure,
  responses,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "binance-connector";
  version = "3.9.0";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "binance";
    repo = "${pname}-python";
    tag = "v${version}";
    hash = "sha256-i0dJ7UO7HZ9bWhWtWBZ5OwloRBUiZgUKRXab4sm2w/o=";
  };

  propagatedBuildInputs = [
    requests
    pycryptodome
    websocket-client
  ];

  nativeCheckInputs = [
    pytest-cov-stub
    pytest
    sure
    responses
    pytestCheckHook
  ];

  # pytestCheckHook attempts to run examples directory, which requires
  # network access
  disabledTestPaths = [ "examples/" ];

  pythonImportsCheck = [
    "binance.spot"
    "binance.websocket"
  ];

  meta = with lib; {
    description = "Simple connector to Binance Public API";
    homepage = "https://github.com/binance/binance-connector-python";
    license = licenses.mit;
    maintainers = with maintainers; [ trishtzy ];
  };
}
