{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
}:

buildPythonPackage rec {
  pname = "refoss-ha";
  version = "1.2.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "ashionky";
    repo = "refoss_ha";
    tag = "v${version}";
    hash = "sha256-DFP2lEZkjW5L94CnhJS04ydM66gnKzvgpiXOAejs768=";
  };

  build-system = [ setuptools ];

  pythonImportsCheck = [ "refoss_ha" ];

  # upstream has no tests
  doCheck = false;

  meta = {
    changelog = "https://github.com/ashionky/refoss_ha/releases/tag/v${version}";
    description = "Refoss support for Home Assistant";
    homepage = "https://github.com/ashionky/refoss_ha";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ dotlambda ];
  };
}
