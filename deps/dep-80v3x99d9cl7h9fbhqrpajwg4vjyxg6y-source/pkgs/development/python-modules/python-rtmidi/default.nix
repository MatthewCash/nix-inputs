{ lib
, stdenv
, alabaster
, alsa-lib
, buildPythonPackage
, CoreAudio
, CoreMIDI
, CoreServices
, Foundation
, cython_3
, fetchPypi
, flake8
, libjack2
, meson-python
, ninja
, pkg-config
, pythonOlder
, tox
, wheel
}:

buildPythonPackage rec {
  pname = "python-rtmidi";
  version = "1.5.7";
  format = "pyproject";

  disabled = pythonOlder "3.8";

  src = fetchPypi {
    pname = "python_rtmidi";
    inherit version;
    hash = "sha256-3vsaSyrob/OYwjLFPu2lVOJKSfZ96ELnnOuos8p3N00=";
  };

  nativeBuildInputs = [
    cython_3
    meson-python
    ninja
    pkg-config
    wheel
  ];

  buildInputs = [
  ] ++ lib.optionals stdenv.isLinux [
    libjack2
    alsa-lib
  ] ++ lib.optionals stdenv.isDarwin [
    CoreAudio
    CoreMIDI
    CoreServices
    Foundation
  ];

  nativeCheckInputs = [
    tox
    flake8
    alabaster
  ];

  pythonImportsCheck = [
    "rtmidi"
  ];

  meta = with lib; {
    description = "A Python binding for the RtMidi C++ library implemented using Cython";
    homepage = "https://github.com/SpotlightKid/python-rtmidi";
    changelog = "https://github.com/SpotlightKid/python-rtmidi/blob/${version}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ hexa ];
  };
}