{
  lib,
  fetchurl,
  buildDunePackage,
  domain-name,
  fmt,
  logs,
  kdf,
  mirage-crypto,
  mirage-crypto-ec,
  mirage-crypto-pk,
  mirage-crypto-rng,
  x509,
  ipaddr,
  alcotest,
  ounit2,
}:

buildDunePackage rec {
  pname = "tls";
  version = "1.0.2";

  src = fetchurl {
    url = "https://github.com/mirleft/ocaml-tls/releases/download/v${version}/tls-${version}.tbz";
    hash = "sha256-ohdRIAyzFG/+FUf11t4Ye1FH6O5r7RKwnVLAAtQrP+s=";
  };

  minimalOCamlVersion = "4.08";

  propagatedBuildInputs = [
    domain-name
    fmt
    logs
    kdf
    mirage-crypto
    mirage-crypto-ec
    mirage-crypto-pk
    mirage-crypto-rng
    x509
    ipaddr
  ];

  doCheck = true;
  checkInputs = [
    alcotest
    ounit2
  ];

  meta = with lib; {
    homepage = "https://github.com/mirleft/ocaml-tls";
    description = "TLS in pure OCaml";
    license = licenses.bsd2;
    maintainers = with maintainers; [ sternenseemann ];
  };
}
