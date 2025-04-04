{
  lib,
  aiohttp,
  beautifulsoup4,
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "aiovodafone";
  version = "0.7.1";
  pyproject = true;

  disabled = pythonOlder "3.11";

  src = fetchFromGitHub {
    owner = "chemelli74";
    repo = "aiovodafone";
    tag = "v${version}";
    hash = "sha256-BVuDnIp9K+f4jZPPfCABMD+fpPXDQE6/RWTZ8k7ftMI=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail " --cov=aiovodafone --cov-report=term-missing:skip-covered" ""
  '';

  build-system = [ poetry-core ];

  dependencies = [
    aiohttp
    beautifulsoup4
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "aiovodafone" ];

  meta = with lib; {
    description = "Library to control Vodafon Station";
    homepage = "https://github.com/chemelli74/aiovodafone";
    changelog = "https://github.com/chemelli74/aiovodafone/blob/v${version}/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ fab ];
  };
}
