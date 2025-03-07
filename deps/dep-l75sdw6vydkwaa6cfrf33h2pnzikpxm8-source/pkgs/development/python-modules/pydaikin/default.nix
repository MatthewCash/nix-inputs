{
  lib,
  aiohttp,
  buildPythonPackage,
  fetchFromGitHub,
  freezegun,
  netifaces,
  pytest-aiohttp,
  pytestCheckHook,
  pythonOlder,
  urllib3,
  setuptools,
  tenacity,
}:

buildPythonPackage rec {
  pname = "pydaikin";
  version = "2.13.7";
  pyproject = true;

  disabled = pythonOlder "3.11";

  src = fetchFromGitHub {
    owner = "fredrike";
    repo = "pydaikin";
    tag = "v${version}";
    hash = "sha256-pLr878LbflRlHzDjarwDLQFHbRZjRvlAZEqP1tfVBNA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    aiohttp
    netifaces
    urllib3
    tenacity
  ];

  doCheck = false; # tests fail and upstream does not seem to run them either

  nativeCheckInputs = [
    freezegun
    pytest-aiohttp
    pytestCheckHook
  ];

  pythonImportsCheck = [ "pydaikin" ];

  meta = with lib; {
    description = "Python Daikin HVAC appliances interface";
    homepage = "https://github.com/fredrike/pydaikin";
    changelog = "https://github.com/fredrike/pydaikin/releases/tag/v${version}";
    license = with licenses; [ gpl3Only ];
    maintainers = with maintainers; [ fab ];
    mainProgram = "pydaikin";
  };
}
