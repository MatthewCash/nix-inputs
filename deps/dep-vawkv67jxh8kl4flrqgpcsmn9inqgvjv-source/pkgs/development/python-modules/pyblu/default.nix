{
  aiohttp,
  aioresponses,
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  lxml,
  poetry-core,
  pytest-asyncio,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "pyblu";
  version = "1.0.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "LouisChrist";
    repo = "pyblu";
    tag = "v${version}";
    hash = "sha256-BDuptBC72XG+q/5MlbPMjYDIhWKg4gfEo2pLOflwQaM=";
  };

  pythonRelaxDeps = [ "aiohttp" ];

  build-system = [ poetry-core ];

  dependencies = [
    aiohttp
    lxml
  ];

  pythonImportsCheck = [ "pyblu" ];

  nativeCheckInputs = [
    aioresponses
    pytest-asyncio
    pytestCheckHook
  ];

  meta = {
    changelog = "https://github.com/LouisChrist/pyblu/releases/tag/v${version}";
    description = "BluOS API client";
    homepage = "https://github.com/LouisChrist/pyblu";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ dotlambda ];
  };
}
