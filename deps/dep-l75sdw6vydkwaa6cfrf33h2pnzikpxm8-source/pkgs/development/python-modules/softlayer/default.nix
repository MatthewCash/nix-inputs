{
  lib,
  buildPythonPackage,
  click,
  fetchFromGitHub,
  mock,
  prettytable,
  prompt-toolkit,
  ptable,
  pygments,
  pytestCheckHook,
  pythonOlder,
  requests,
  rich,
  sphinx,
  testtools,
  tkinter,
  urllib3,
  zeep,
}:

buildPythonPackage rec {
  pname = "softlayer";
  version = "6.2.5";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = pname;
    repo = "softlayer-python";
    tag = "v${version}";
    hash = "sha256-wDLMVonPUexoaZ60kRBILmr5l46yajzACozCp6uETGY=";
  };

  postPatch = ''
    substituteInPlace setup.py \
        --replace "rich ==" "rich >="
  '';

  propagatedBuildInputs = [
    click
    prettytable
    prompt-toolkit
    ptable
    pygments
    requests
    rich
    urllib3
  ];

  __darwinAllowLocalNetworking = true;

  nativeCheckInputs = [
    mock
    pytestCheckHook
    sphinx
    testtools
    tkinter
    zeep
  ];

  # Otherwise soap_tests.py will fail to create directory
  # Permission denied: '/homeless-shelter'
  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  disabledTestPaths = [
    # Test fails with ConnectionError trying to connect to api.softlayer.com
    "tests/transports/soap_tests.py.unstable"
  ];

  pythonImportsCheck = [ "SoftLayer" ];

  meta = with lib; {
    description = "Python libraries that assist in calling the SoftLayer API";
    homepage = "https://github.com/softlayer/softlayer-python";
    changelog = "https://github.com/softlayer/softlayer-python/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ onny ];
  };
}
