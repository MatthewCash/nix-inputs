{
  lib,
  rustPlatform,
  fetchCrate,
  docutils,
  installShellFiles,
}:

rustPlatform.buildRustPackage rec {
  pname = "mdevctl";
  version = "1.3.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-4K4NW3DOTtzZJ7Gg0mnRPr88YeqEjTtKX+C4P8i923E=";
  };

  # https://github.com/mdevctl/mdevctl/issues/111
  patches = [
    ./script-dir.patch
  ];

  useFetchCargoVendor = true;
  cargoHash = "sha256-xfrW7WiKBM9Hz49he/42z9gBrwZ3sKGH/u105hcyln0=";

  nativeBuildInputs = [
    docutils
    installShellFiles
  ];

  postInstall = ''
    ln -s mdevctl $out/bin/lsmdev

    install -Dm444 60-mdevctl.rules -t $out/lib/udev/rules.d

    installManPage $releaseDir/build/mdevctl-*/out/mdevctl.8
    ln -s mdevctl.8 $out/share/man/man8/lsmdev.8

    installShellCompletion $releaseDir/build/mdevctl-*/out/{lsmdev,mdevctl}.bash
  '';

  meta = with lib; {
    homepage = "https://github.com/mdevctl/mdevctl";
    description = "Mediated device management utility for linux";
    license = licenses.lgpl21Only;
    maintainers = with maintainers; [ edwtjo ];
    platforms = platforms.linux;
  };
}
