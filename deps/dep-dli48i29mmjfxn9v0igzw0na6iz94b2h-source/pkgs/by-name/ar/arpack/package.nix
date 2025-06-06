{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  gfortran,
  blas,
  lapack,
  eigen,
  useMpi ? false,
  mpi,
  openssh,
  igraph,
  useAccel ? false, # use Accelerate framework on darwin
}:

# MPI version can only be built with LP64 interface.
# See https://github.com/opencollab/arpack-ng#readme
assert useMpi -> !blas.isILP64;
assert useAccel -> stdenv.hostPlatform.isDarwin;

stdenv.mkDerivation rec {
  pname = "arpack";
  version = "3.9.1";

  src = fetchFromGitHub {
    owner = "opencollab";
    repo = "arpack-ng";
    rev = version;
    sha256 = "sha256-HCvapLba8oLqx9I5+KDAU0s/dTmdWOEilS75i4gyfC0=";
  };

  nativeBuildInputs = [
    cmake
    gfortran
    ninja
  ];
  buildInputs =
    [
      eigen
    ]
    ++ lib.optionals (!useAccel) (
      assert (blas.isILP64 == lapack.isILP64);
      [
        blas
        lapack
      ]
    )
    ++ lib.optional useMpi mpi;

  nativeCheckInputs = lib.optional useMpi openssh;

  # a couple tests fail when run in parallel
  doCheck = true;
  enableParallelChecking = false;

  env = lib.optionalAttrs useAccel {
    # Without these flags some tests will fail / segfault when using Accelerate
    # framework. They were pulled from the CI Workflow
    # https://github.com/opencollab/arpack-ng/blob/804fa3149a0f773064198a8e883bd021832157ca/.github/workflows/jobs.yml#L184-L192
    FFLAGS = "-ff2c -fno-second-underscore";
  };

  cmakeFlags =
    [
      (lib.cmakeBool "BUILD_SHARED_LIBS" stdenv.hostPlatform.hasSharedLibraries)
      (lib.cmakeBool "EIGEN" true)
      (lib.cmakeBool "EXAMPLES" true)
      (lib.cmakeBool "ICB" true)
      (lib.cmakeBool "INTERFACE64" (!useAccel && blas.isILP64))
      (lib.cmakeBool "MPI" useMpi)
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      "-DBLA_VENDOR=${if useAccel then "Apple" else "Generic"}"
    ];

  passthru = {
    isILP64 = !useAccel && blas.isILP64;
    tests = {
      inherit igraph;
    };
  };

  meta = {
    homepage = "https://github.com/opencollab/arpack-ng";
    changelog = "https://github.com/opencollab/arpack-ng/blob/${src.rev}/CHANGES";
    description = ''
      A collection of Fortran77 subroutines to solve large scale eigenvalue
      problems.
    '';
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [
      ttuegel
      dotlambda
    ];
    platforms = lib.platforms.unix;
  };
}
