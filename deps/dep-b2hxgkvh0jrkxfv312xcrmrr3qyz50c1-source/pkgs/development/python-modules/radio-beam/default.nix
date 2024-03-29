{ lib
, fetchPypi
, buildPythonPackage
, setuptools-scm
, astropy
, numpy
, matplotlib
, scipy
, six
, pytestCheckHook
, pytest-astropy
}:

buildPythonPackage rec {
  pname = "radio-beam";
  version = "0.3.6";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-U+IjOTt7x9uzUl7IcQRu2s+MBKF/OR+sLddvHmp9hqU=";
  };

  nativeBuildInputs = [
    setuptools-scm
  ];

  propagatedBuildInputs = [
    astropy
    numpy
    scipy
    six
  ];

  nativeCheckInputs = [
    pytestCheckHook
    matplotlib
    pytest-astropy
  ];

  pythonImportsCheck = [
    "radio_beam"
  ];

  meta = with lib; {
    description = "Tools for Beam IO and Manipulation";
    homepage = "http://radio-astro-tools.github.io";
    changelog = "https://github.com/radio-astro-tools/radio-beam/releases/tag/v${version}";
    license = licenses.bsd3;
    maintainers = with maintainers; [ smaret ];
  };
}


