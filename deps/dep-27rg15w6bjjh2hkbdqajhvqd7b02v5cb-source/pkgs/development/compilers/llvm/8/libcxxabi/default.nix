{ lib, stdenv, llvm_meta, cmake, fetch, libcxx, libunwind, llvm, version
, enableShared ? !stdenv.hostPlatform.isStatic
}:

stdenv.mkDerivation {
  pname = "libcxxabi";
  inherit version;

  src = fetch "libcxxabi" "1vznz8n1z1h8af0ga451m98lc2hjnv4fyzl71napsvjhvk4g6nxp";

  outputs = [ "out" "dev" ];

  postUnpack = ''
    unpackFile ${libcxx.src}
    unpackFile ${llvm.src}
    cmakeFlags+=" -DLLVM_PATH=$PWD/$(ls -d llvm-*) -DLIBCXXABI_LIBCXX_PATH=$PWD/$(ls -d libcxx-*)"
  '' + lib.optionalString stdenv.isDarwin ''
    export TRIPLE=x86_64-apple-darwin
  '' + lib.optionalString stdenv.hostPlatform.isMusl ''
    patch -p1 -d $(ls -d libcxx-*) -i ${../../common/libcxx/libcxx-0001-musl-hacks.patch}
  '' + lib.optionalString stdenv.hostPlatform.isWasm ''
    patch -p1 -d $(ls -d llvm-*) -i ${./wasm.patch}
  '';

  patches = [
    ../../common/libcxxabi/no-threads.patch
    ./gnu-install-dirs.patch
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = lib.optional (!stdenv.isDarwin && !stdenv.hostPlatform.isWasm) libunwind;

  cmakeFlags = lib.optionals (stdenv.hostPlatform.useLLVM or false) [
    "-DLLVM_ENABLE_LIBCXX=ON"
    "-DLIBCXXABI_USE_LLVM_UNWINDER=ON"
  ] ++ lib.optionals stdenv.hostPlatform.isWasm [
    "-DLIBCXXABI_ENABLE_THREADS=OFF"
    "-DLIBCXXABI_ENABLE_EXCEPTIONS=OFF"
  ] ++ lib.optionals (!enableShared) [
    "-DLIBCXXABI_ENABLE_SHARED=OFF"
  ];

  preInstall = lib.optionalString stdenv.isDarwin ''
    for file in lib/*.dylib; do
      if [ -L "$file" ]; then continue; fi

      # Fix up the install name. Preserve the basename, just replace the path.
      installName="$out/lib/$(basename $(${stdenv.cc.targetPrefix}otool -D $file | tail -n 1))"

      # this should be done in CMake, but having trouble figuring out
      # the magic combination of necessary CMake variables
      # if you fancy a try, take a look at
      # https://gitlab.kitware.com/cmake/community/-/wikis/doc/cmake/RPATH-handling
      ${stdenv.cc.targetPrefix}install_name_tool -id $installName $file

      # cc-wrapper passes '-lc++abi' to all c++ link steps, but that causes
      # libcxxabi to sometimes link against a different version of itself.
      # Here we simply make that second reference point to ourselves.
      for other in $(${stdenv.cc.targetPrefix}otool -L $file | awk '$1 ~ "/libc\\+\\+abi" { print $1 }'); do
        ${stdenv.cc.targetPrefix}install_name_tool -change $other $installName $file
      done
    done
  '';

  postInstall = ''
    mkdir -p "$dev/include"
    install -m 644 ../include/${if stdenv.isDarwin then "*" else "cxxabi.h"} "$dev/include"
  '';

  passthru = {
    libName = "c++abi";
  };

  meta = llvm_meta // {
    homepage = "https://libcxxabi.llvm.org/";
    description = "Provides C++ standard library support";
    longDescription = ''
      libc++abi is a new implementation of low level support for a standard C++ library.
    '';
    # "All of the code in libc++abi is dual licensed under the MIT license and
    # the UIUC License (a BSD-like license)":
    license = with lib.licenses; [ mit ncsa ];
    maintainers = llvm_meta.maintainers ++ [ lib.maintainers.vlstill ];
  };
}
