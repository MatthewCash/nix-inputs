{ lib, stdenv
, fetchFromGitHub
, gfortran
, blas, lapack
, metis
, fixDarwinDylibNames
, gmp
, mpfr
, config
, enableCuda ? config.cudaSupport
, cudatoolkit
}:

stdenv.mkDerivation rec {
  pname = "suitesparse";
  version = "5.13.0";

  outputs = [ "out" "dev" "doc" ];

  src = fetchFromGitHub {
    owner = "DrTimothyAldenDavis";
    repo = "SuiteSparse";
    rev = "v${version}";
    sha256 = "sha256-Anen1YtXsSPhk8DpA4JtADIz9m8oXFl9umlkb4iImf8=";
  };

  nativeBuildInputs = [
  ] ++ lib.optional stdenv.isDarwin fixDarwinDylibNames;

  # Use compatible indexing for lapack and blas used
  buildInputs = assert (blas.isILP64 == lapack.isILP64); [
    blas lapack
    metis
    gfortran.cc.lib
    gmp
    mpfr
  ] ++ lib.optional enableCuda cudatoolkit;

  preConfigure = ''
    # Mongoose and GraphBLAS are packaged separately
    sed -i "Makefile" -e '/GraphBLAS\|Mongoose/d'
  '';

  makeFlags = [
    "INSTALL=${placeholder "out"}"
    "INSTALL_INCLUDE=${placeholder "dev"}/include"
    "JOBS=$(NIX_BUILD_CORES)"
    "MY_METIS_LIB=-lmetis"
  ] ++ lib.optionals blas.isILP64 [
    "CFLAGS=-DBLAS64"
  ] ++ lib.optionals enableCuda [
    "CUDA_PATH=${cudatoolkit}"
    "CUDART_LIB=${cudatoolkit.lib}/lib/libcudart.so"
    "CUBLAS_LIB=${cudatoolkit}/lib/libcublas.so"
  ] ++ lib.optionals stdenv.isDarwin [
    # Unless these are set, the build will attempt to use `Accelerate` on darwin, see:
    # https://github.com/DrTimothyAldenDavis/SuiteSparse/blob/v5.13.0/SuiteSparse_config/SuiteSparse_config.mk#L368
    "BLAS=-lblas"
    "LAPACK=-llapack"
  ]
  ;

  env = lib.optionalAttrs stdenv.isDarwin {
    # Ensure that there is enough space for the `fixDarwinDylibNames` hook to
    # update the install names of the output dylibs.
    NIX_LDFLAGS = "-headerpad_max_install_names";
  };

  buildFlags = [
    # Build individual shared libraries, not demos
    "library"
  ];

  meta = with lib; {
    homepage = "http://faculty.cse.tamu.edu/davis/suitesparse.html";
    description = "A suite of sparse matrix algorithms";
    license = with licenses; [ bsd2 gpl2Plus lgpl21Plus ];
    maintainers = with maintainers; [ ttuegel ];
    platforms = with platforms; unix;
  };
}