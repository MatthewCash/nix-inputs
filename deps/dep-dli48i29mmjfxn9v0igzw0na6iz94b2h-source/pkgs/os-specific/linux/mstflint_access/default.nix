{
  lib,
  stdenv,
  fetchurl,
  kernel,
  kmod,
  mstflint,
  kernelModuleMakeFlags,
}:

stdenv.mkDerivation rec {
  pname = "mstflint_access";
  inherit (mstflint) version;

  src = fetchurl {
    url = "https://github.com/Mellanox/mstflint/releases/download/v${version}/kernel-mstflint-${version}.tar.gz";
    hash = "sha256-D++AnLUEB8d9WlReY/Ewp8E2cvbapJ3QrvYySKwaszk=";
  };

  nativeBuildInputs = [ kmod ] ++ kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "KVER=${kernel.modDirVersion}"
    "KSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    install -D ${pname}.ko $out/lib/modules/${kernel.modDirVersion}/extra/${pname}.ko

    runHook postInstall
  '';

  meta = with lib; {
    description = "Kernel module for Nvidia NIC firmware update";
    homepage = "https://github.com/Mellanox/mstflint";
    license = [ licenses.gpl2Only ];
    maintainers = with maintainers; [ thillux ];
    platforms = platforms.linux;
  };
}
