{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  importlib-metadata,
  jinja2,
  markdown,
  markupsafe,
  mkdocs,
  mkdocs-autorefs,
  pdm-backend,
  pymdown-extensions,
  pytestCheckHook,
  pythonOlder,
  typing-extensions,
}:

buildPythonPackage rec {
  pname = "mkdocstrings";
  version = "0.26.2";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "mkdocstrings";
    repo = "mkdocstrings";
    tag = version;
    hash = "sha256-xZKE8+bNHL+GSQS00MlShOl/3p7+mRV558Pel50ipOI=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'dynamic = ["version"]' 'version = "${version}"'
  '';

  build-system = [ pdm-backend ];

  dependencies =
    [
      jinja2
      markdown
      markupsafe
      mkdocs
      mkdocs-autorefs
      pymdown-extensions
    ]
    ++ lib.optionals (pythonOlder "3.10") [
      importlib-metadata
      typing-extensions
    ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "mkdocstrings" ];

  disabledTestPaths = [
    # Circular dependencies
    "tests/test_extension.py"
  ];

  disabledTests = [
    # Not all requirements are available
    "test_disabling_plugin"
    # Circular dependency on mkdocstrings-python
    "test_extended_templates"
  ];

  meta = with lib; {
    description = "Automatic documentation from sources for MkDocs";
    homepage = "https://github.com/mkdocstrings/mkdocstrings";
    changelog = "https://github.com/mkdocstrings/mkdocstrings/blob/${version}/CHANGELOG.md";
    license = licenses.isc;
    maintainers = with maintainers; [ fab ];
  };
}
