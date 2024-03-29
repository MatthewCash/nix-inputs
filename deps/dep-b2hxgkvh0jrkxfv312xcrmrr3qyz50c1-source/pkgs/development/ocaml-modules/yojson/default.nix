{ lib, fetchurl, buildDunePackage, cppo, seq }:

buildDunePackage rec {
  pname = "yojson";
  version = "2.1.1";

  src = fetchurl {
    url = "https://github.com/ocaml-community/yojson/releases/download/${version}/yojson-${version}.tbz";
    hash = "sha256-1YGDIHsZjcBlhmI5Bm4HTDT54TnA2cQXWjiAl5DogXM=";
  };

  nativeBuildInputs = [ cppo ];
  propagatedBuildInputs = [ seq ];

  meta = with lib; {
    description = "An optimized parsing and printing library for the JSON format";
    homepage = "https://github.com/ocaml-community/${pname}";
    license = licenses.bsd3;
    maintainers = [ maintainers.vbgl ];
    mainProgram = "ydump";
  };
}
