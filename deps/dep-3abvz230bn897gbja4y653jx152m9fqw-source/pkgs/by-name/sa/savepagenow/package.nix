{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "savepagenow";
  version = "1.1.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pastpages";
    repo = "savepagenow";
    rev = "v${version}";
    sha256 = "1lz6rc47cds9rb35jdf8n13gr61wdkh5jqzx4skikm1yrqkwjyhm";
  };

  build-system = with python3Packages; [ setuptools ];

  dependencies = with python3Packages; [
    click
    requests
  ];

  # requires network access
  doCheck = false;

  pythonImportsCheck = [ "savepagenow" ];

  meta = with lib; {
    description = "Simple Python wrapper for archive.org's \"Save Page Now\" capturing service";
    homepage = "https://github.com/pastpages/savepagenow";
    license = licenses.mit;
    maintainers = with maintainers; [ SuperSandro2000 ];
    mainProgram = "savepagenow";
  };
}
