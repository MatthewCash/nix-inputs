{
  lib,
  buildPythonPackage,
  cryptography,
  dnspython,
  expiringdict,
  fetchFromGitHub,
  hatchling,
  publicsuffixlist,
  pyleri,
  pytestCheckHook,
  pythonOlder,
  requests,
  timeout-decorator,
}:

buildPythonPackage rec {
  pname = "checkdmarc";
  version = "5.5.0";
  format = "pyproject";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "domainaware";
    repo = "checkdmarc";
    tag = version;
    hash = "sha256-skQqLWBEmfyiW2DsRRbj3Lfj52QZca0zKenFC7LltjM=";
  };

  nativeBuildInputs = [ hatchling ];

  propagatedBuildInputs = [
    cryptography
    dnspython
    expiringdict
    publicsuffixlist
    pyleri
    requests
    timeout-decorator
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "checkdmarc" ];

  pytestFlagsArray = [ "tests.py" ];

  disabledTests = [
    # Tests require network access
    "testDMARCPctLessThan100Warning"
    "testSPFMissingARecord"
    "testSPFMissingMXRecord"
    "testSplitSPFRecord"
    "testTooManySPFDNSLookups"
    "testTooManySPFVoidDNSLookups"
  ];

  meta = with lib; {
    description = "Parser for SPF and DMARC DNS records";
    mainProgram = "checkdmarc";
    homepage = "https://github.com/domainaware/checkdmarc";
    changelog = "https://github.com/domainaware/checkdmarc/blob/${version}/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ fab ];
  };
}
