{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,
  substituteAll,
  ruff,
  click,
  click-default-group,
  docformatter,
  jinja2,
  toposort,
  typing-extensions,
  lxml,
  requests,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage rec {
  pname = "xsdata";
  version = "24.11";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "tefra";
    repo = "xsdata";
    tag = "v${version}";
    hash = "sha256-hyNC9VcWkGnOYm6BpXgH3RzmHTqBVmQoADvcEvgF6yg=";
  };

  patches = [
    (substituteAll {
      src = ./paths.patch;
      ruff = lib.getExe ruff;
    })
  ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "--benchmark-skip" ""
  '';

  build-system = [ setuptools ];

  dependencies = [ typing-extensions ];

  optional-dependencies = {
    cli = [
      click
      click-default-group
      docformatter
      jinja2
      toposort
    ];
    lxml = [ lxml ];
    soap = [ requests ];
  };

  nativeCheckInputs =
    [
      pytestCheckHook
    ]
    ++ optional-dependencies.cli
    ++ optional-dependencies.lxml
    ++ optional-dependencies.soap;

  disabledTestPaths = [ "tests/integration/benchmarks" ];

  pythonImportsCheck = [
    "xsdata.formats.dataclass.context"
    "xsdata.formats.dataclass.models.elements"
    "xsdata.formats.dataclass.models.generics"
    "xsdata.formats.dataclass.parsers"
    "xsdata.formats.dataclass.parsers.handlers"
    "xsdata.formats.dataclass.parsers.nodes"
    "xsdata.formats.dataclass.serializers"
    "xsdata.formats.dataclass.serializers.config"
    "xsdata.formats.dataclass.serializers.mixins"
    "xsdata.formats.dataclass.serializers.writers"
    "xsdata.models.config"
    "xsdata.utils.text"
  ];

  meta = {
    description = "Naive XML & JSON bindings for Python";
    mainProgram = "xsdata";
    homepage = "https://github.com/tefra/xsdata";
    changelog = "https://github.com/tefra/xsdata/blob/${src.rev}/CHANGES.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ dotlambda ];
  };
}
