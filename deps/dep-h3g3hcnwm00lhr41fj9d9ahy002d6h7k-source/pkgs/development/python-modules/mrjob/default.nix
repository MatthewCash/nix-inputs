{
  lib,
  buildPythonPackage,
  pythonAtLeast,
  fetchFromGitHub,

  # propagates
  pyyaml,

  # optionals
  boto3,
  botocore,
  google-cloud-dataproc,
  google-cloud-logging,
  google-cloud-storage,
  python-rapidjson,
  simplejson,
  ujson,

  # tests
  pyspark,
  unittestCheckHook,
  warcio,
}:

buildPythonPackage rec {
  pname = "mrjob";
  version = "0.7.4";

  # https://github.com/Yelp/mrjob/issues/2222
  disabled = pythonAtLeast "3.12";

  src = fetchFromGitHub {
    owner = "Yelp";
    repo = "mrjob";
    tag = "v${version}";
    hash = "sha256-Yp4yUx6tkyGB622I9y+AWK2AkIDVGKQPMM+LtB/M3uo=";
  };

  propagatedBuildInputs = [ pyyaml ];

  optional-dependencies = {
    aws = [
      boto3
      botocore
    ];
    google = [
      google-cloud-dataproc
      google-cloud-logging
      google-cloud-storage
    ];
    rapidjson = [ python-rapidjson ];
    simplejson = [ simplejson ];
    ujson = [ ujson ];
  };

  doCheck = false; # failing tests

  nativeCheckInputs = [
    pyspark
    unittestCheckHook
    warcio
  ] ++ lib.flatten (builtins.attrValues optional-dependencies);

  unittestFlagsArray = [ "-v" ];

  meta = with lib; {
    changelog = "https://github.com/Yelp/mrjob/blob/v${version}/CHANGES.txt";
    description = "Run MapReduce jobs on Hadoop or Amazon Web Services";
    homepage = "https://github.com/Yelp/mrjob";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
