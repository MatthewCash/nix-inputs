{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  cargo,
  pkg-config,
  glibc,
  openssl,
  libepoxy,
  libdrm,
  pipewire,
  virglrenderer,
  libkrunfw,
  llvmPackages,
  rustc,
  withGpu ? false,
  withSound ? false,
  withNet ? false,
  sevVariant ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libkrun";
  version = "1.9.6";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "libkrun";
    tag = "v${finalAttrs.version}";
    hash = "sha256-bseyOHgteLEUz93gL5G2zR0ssijMd86zmlvm02a7FSY=";
  };

  outputs = [
    "out"
    "dev"
  ];

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit (finalAttrs) src;
    hash = "sha256-OerD2SEJquv7bHEZw4jdxmrQn8SuIUJiYPu9E1u439o=";
  };

  nativeBuildInputs = [
    llvmPackages.clang
    rustPlatform.cargoSetupHook
    cargo
    rustc
  ] ++ lib.optional (sevVariant || withGpu) pkg-config;

  buildInputs =
    [
      (libkrunfw.override { inherit sevVariant; })
      glibc
      glibc.static
    ]
    ++ lib.optionals withGpu [
      libepoxy
      libdrm
      virglrenderer
    ]
    ++ lib.optional withSound pipewire
    ++ lib.optional sevVariant openssl;

  env.LIBCLANG_PATH = "${lib.getLib llvmPackages.clang-unwrapped}/lib/libclang.so";

  makeFlags =
    [
      "PREFIX=${placeholder "out"}"
    ]
    ++ lib.optional withGpu "GPU=1"
    ++ lib.optional withSound "SND=1"
    ++ lib.optional withNet "NET=1"
    ++ lib.optional sevVariant "SEV=1";

  postInstall = ''
    mkdir -p $dev/lib/pkgconfig
    mv $out/lib64/pkgconfig $dev/lib/pkgconfig
    mv $out/include $dev/include
  '';

  meta = with lib; {
    description = "Dynamic library providing Virtualization-based process isolation capabilities";
    homepage = "https://github.com/containers/libkrun";
    license = licenses.asl20;
    maintainers = with maintainers; [
      nickcao
      RossComputerGuy
    ];
    platforms = libkrunfw.meta.platforms;
  };
})
