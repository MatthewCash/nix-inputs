{
  lib,
  buildPythonPackage,
  emoji,
  fetchFromGitHub,
  freezegun,
  tzdata,
  pyparsing,
  pydantic,
  pytest-benchmark,
  pytestCheckHook,
  pythonOlder,
  python-dateutil,
  setuptools,
  syrupy,
}:

buildPythonPackage rec {
  pname = "ical";
  version = "8.2.0";
  pyproject = true;

  disabled = pythonOlder "3.10";

  src = fetchFromGitHub {
    owner = "allenporter";
    repo = "ical";
    tag = version;
    hash = "sha256-9mnyhDKcZTZAGRxojQN9I9ZAgBmsSSsBPzCMZO6Rl5k=";
  };

  build-system = [ setuptools ];

  dependencies = [
    python-dateutil
    tzdata
    pydantic
    pyparsing
  ];

  nativeCheckInputs = [
    emoji
    freezegun
    pytest-benchmark
    pytestCheckHook
    syrupy
  ];

  disabledTests = [
    # Missing timezone due to out of date tzdata
    # ical.tzif.timezoneinfo.TimezoneInfoError: Unable to load tzdata module: America/Coyhaique
    "test_all_zoneinfo"
  ];

  pythonImportsCheck = [ "ical" ];

  meta = with lib; {
    description = "Library for handling iCalendar";
    homepage = "https://github.com/allenporter/ical";
    changelog = "https://github.com/allenporter/ical/releases/tag/${version}";
    license = licenses.asl20;
    maintainers = with maintainers; [ dotlambda ];
  };
}
