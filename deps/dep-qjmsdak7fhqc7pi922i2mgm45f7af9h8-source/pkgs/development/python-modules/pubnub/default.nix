{
  lib,
  aiohttp,
  buildPythonPackage,
  busypie,
  cbor2,
  fetchFromGitHub,
  pycryptodomex,
  pytestCheckHook,
  pytest-vcr,
  pytest-asyncio,
  requests,
  pythonOlder,
  setuptools,
}:

buildPythonPackage rec {
  pname = "pubnub";
  version = "9.0.0";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "pubnub";
    repo = "python";
    tag = "v${version}";
    hash = "sha256-v3tFbq2YvQJRvRu9+8yzWLkFo+7AMsJDlqjMK2Q/FAE=";
  };

  build-system = [ setuptools ];

  dependencies = [
    aiohttp
    cbor2
    pycryptodomex
    requests
  ];

  nativeCheckInputs = [
    busypie
    pytest-asyncio
    pytest-vcr
    pytestCheckHook
  ];

  disabledTestPaths = [
    # Tests require network access
    "tests/integrational"
    "tests/manual"
    "tests/functional/push"
  ];

  disabledTests = [
    "test_subscribe"
    "test_handshaking"
  ];

  pythonImportsCheck = [ "pubnub" ];

  meta = with lib; {
    description = "Python-based APIs for PubNub";
    homepage = "https://github.com/pubnub/python";
    changelog = "https://github.com/pubnub/python/releases/tag/v${version}";
    # PubNub Software Development Kit License Agreement
    # https://github.com/pubnub/python/blob/master/LICENSE
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [ fab ];
  };
}
