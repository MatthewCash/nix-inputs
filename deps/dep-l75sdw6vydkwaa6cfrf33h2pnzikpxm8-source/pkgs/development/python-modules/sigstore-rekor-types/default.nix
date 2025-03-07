{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  pydantic,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "sigstore-rekor-types";
  version = "0.0.13";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "trailofbits";
    repo = "sigstore-rekor-types";
    tag = "v${version}";
    hash = "sha256-vZNzNu0Ks0Xp/v406jVqPV9FuHgXORMa7NzmXeWoa+Q=";
  };

  build-system = [ flit-core ];

  dependencies = [ pydantic ] ++ pydantic.optional-dependencies.email;

  # Module has no tests
  doCheck = false;

  meta = with lib; {
    description = "Python models for Rekor's API types";
    homepage = "https://github.com/trailofbits/sigstore-rekor-types";
    changelog = "https://github.com/trailofbits/sigstore-rekor-types/releases/tag/v${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ fab ];
  };
}
