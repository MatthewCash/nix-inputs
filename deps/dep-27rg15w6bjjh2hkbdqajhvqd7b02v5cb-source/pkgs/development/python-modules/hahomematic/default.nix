{ lib
, aiohttp
, buildPythonPackage
, fetchFromGitHub
, freezegun
, orjson
, pydevccu
, pytest-aiohttp
, pytestCheckHook
, python-slugify
, pythonOlder
, setuptools
, voluptuous
, websocket-client
, xmltodict
, wheel
}:

buildPythonPackage rec {
  pname = "hahomematic";
  version = "2023.11.1";
  format = "pyproject";

  disabled = pythonOlder "3.11";

  src = fetchFromGitHub {
    owner = "danielperna84";
    repo = pname;
    rev = "refs/tags/${version}";
    hash = "sha256-C8KznmR3+G38MLQj6Sek7qW9R9yJr8gfcjgNjDyXG7I=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace "setuptools~=68.2" "setuptools" \
      --replace "wheel~=0.41.2" "wheel"
  '';

  nativeBuildInputs = [
    setuptools
    wheel
  ];

  propagatedBuildInputs = [
    aiohttp
    orjson
    python-slugify
    voluptuous
  ];

  nativeCheckInputs = [
    freezegun
    pydevccu
    pytest-aiohttp
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "hahomematic"
  ];

  meta = with lib; {
    description = "Python module to interact with HomeMatic devices";
    homepage = "https://github.com/danielperna84/hahomematic";
    changelog = "https://github.com/danielperna84/hahomematic/releases/tag/${version}";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ fab ];
  };
}
