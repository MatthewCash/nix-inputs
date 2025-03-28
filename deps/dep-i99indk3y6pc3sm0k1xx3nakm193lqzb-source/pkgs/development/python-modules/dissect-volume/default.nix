{
  lib,
  buildPythonPackage,
  dissect-cstruct,
  dissect-util,
  fetchFromGitHub,
  setuptools,
  setuptools-scm,
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "dissect-volume";
  version = "3.12";
  pyproject = true;

  disabled = pythonOlder "3.12";

  src = fetchFromGitHub {
    owner = "fox-it";
    repo = "dissect.volume";
    tag = version;
    hash = "sha256-IhG2FZdCmYrGxHc2i+ERhphxP/uGgOY67epHEWnQXb0=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [
    dissect-cstruct
    dissect-util
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "dissect.volume" ];

  disabledTests = [
    # gzip.BadGzipFile: Not a gzipped file
    "test_ddf_read"
    "test_dm_thin"
    "test_lvm"
    "test_lvm_mirro"
    "test_lvm_thin"
    "test_lvm"
    "test_md_raid0_zones"
    "test_md_read"
  ];

  meta = with lib; {
    description = "Dissect module implementing various utility functions for the other Dissect modules";
    homepage = "https://github.com/fox-it/dissect.volume";
    changelog = "https://github.com/fox-it/dissect.volume/releases/tag/${version}";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ fab ];
  };
}
