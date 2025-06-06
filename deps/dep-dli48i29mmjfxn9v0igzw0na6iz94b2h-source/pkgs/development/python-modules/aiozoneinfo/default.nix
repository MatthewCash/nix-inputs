{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
  pytest-asyncio,
  pytestCheckHook,
  pythonOlder,
  tzdata,
}:

buildPythonPackage rec {
  pname = "aiozoneinfo";
  version = "0.2.1";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "bluetooth-devices";
    repo = "aiozoneinfo";
    tag = "v${version}";
    hash = "sha256-u7yQiy5xKK1A19cmpXjA4MMK4q7RvtuvwkUECnddzG8=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "--cov=aiozoneinfo --cov-report=term-missing:skip-covered" ""
  '';

  build-system = [ poetry-core ];

  dependencies = [ tzdata ];

  nativeCheckInputs = [
    pytest-asyncio
    pytestCheckHook
  ];

  pythonImportsCheck = [ "aiozoneinfo" ];

  meta = with lib; {
    description = "Tools to fetch zoneinfo with asyncio";
    homepage = "https://github.com/bluetooth-devices/aiozoneinfo";
    changelog = "https://github.com/bluetooth-devices/aiozoneinfo/blob/${version}/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ fab ];
  };
}
