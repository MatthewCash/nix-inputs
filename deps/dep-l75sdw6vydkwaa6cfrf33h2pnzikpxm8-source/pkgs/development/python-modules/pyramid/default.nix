{
  lib,
  buildPythonPackage,
  fetchPypi,
  webtest,
  zope-component,
  hupper,
  pastedeploy,
  plaster,
  plaster-pastedeploy,
  repoze-lru,
  setuptools,
  translationstring,
  venusian,
  webob,
  zope-deprecation,
  zope-interface,
  pythonOlder,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "pyramid";
  version = "2.0.2";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-NyE4pzjkIWU1zHbczm7d1aGqypUTDyNU+4NCZMBvGN4=";
  };

  build-system = [ setuptools ];

  dependencies = [
    hupper
    pastedeploy
    plaster
    plaster-pastedeploy
    repoze-lru
    setuptools # for pkg_resources
    translationstring
    venusian
    webob
    zope-deprecation
    zope-interface
  ];

  nativeCheckInputs = [
    webtest
    zope-component
    pytestCheckHook
  ];

  pythonImportsCheck = [ "pyramid" ];

  meta = with lib; {
    description = "Python web framework";
    homepage = "https://trypyramid.com/";
    changelog = "https://github.com/Pylons/pyramid/blob/${version}/CHANGES.rst";
    license = licenses.bsd0;
    maintainers = with maintainers; [ domenkozar ];
  };
}
