{
  lib,
  aiohttp,
  aioresponses,
  buildPythonPackage,
  ciso8601,
  click,
  fetchFromGitHub,
  mashumaro,
  poetry-core,
  pytest-asyncio,
  pytest-cov-stub,
  pytestCheckHook,
  pythonOlder,
  rich,
  typer,
  yarl,
}:

buildPythonPackage rec {
  pname = "aiortm";
  version = "0.9.25";
  pyproject = true;

  disabled = pythonOlder "3.12";

  src = fetchFromGitHub {
    owner = "MartinHjelmare";
    repo = "aiortm";
    tag = "v${version}";
    hash = "sha256-rw86RzP8AI+zWchC9c01vdedc6r4gfF5A8DltWW5YRY=";
  };

  pythonRelaxDeps = [ "typer" ];

  build-system = [ poetry-core ];

  dependencies = [
    aiohttp
    ciso8601
    click
    mashumaro
    rich
    typer
    yarl
  ];

  nativeCheckInputs = [
    aioresponses
    pytest-asyncio
    pytest-cov-stub
    pytestCheckHook
  ];

  pythonImportsCheck = [ "aiortm" ];

  meta = with lib; {
    description = "Library for the Remember the Milk API";
    homepage = "https://github.com/MartinHjelmare/aiortm";
    changelog = "https://github.com/MartinHjelmare/aiortm/blob/v${version}/CHANGELOG.md";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ fab ];
    mainProgram = "aiortm";
  };
}
