final: prev:
let
  inherit (prev) lib pkgs;
  cudaVersionOlder = lib.versionOlder final.cudaVersion;
  cudaVersionAtLeast = lib.versionAtLeast final.cudaVersion;
in
(lib.filterAttrs (attr: _: (prev ? "${attr}")) {
  ### Overrides to fix the components of cudatoolkit-redist

  # Attributes that don't exist in the previous set are removed.
  # That means only overrides can go here, and not new expressions!

  libcufile = prev.libcufile.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [
      final.libcublas.lib
      pkgs.numactl
      pkgs.rdma-core
    ];
    # libcuda needs to be resolved during runtime
    autoPatchelfIgnoreMissingDeps =
      ["libcuda.so.1"]
      # Before 12.0 libcufile depends on itself for some reason.
      ++ lib.optionals (cudaVersionOlder "12.0") [
        "libcufile.so.0"
      ];
  });

  libcusolver = final.addBuildInputs prev.libcusolver (
    # Always depends on this
    [final.libcublas.lib]
    # Dependency from 12.0 and on
    ++ lib.optionals (cudaVersionAtLeast "12.0") [
      final.libnvjitlink.lib
    ]
    # Dependency from 12.1 and on
    ++ lib.optionals (cudaVersionAtLeast "12.1") [
      final.libcusparse.lib
    ]
  );

  libcusparse = final.addBuildInputs prev.libcusparse (
    lib.optionals (cudaVersionAtLeast "12.0") [
      final.libnvjitlink.lib
    ]
  );

  cuda_gdb = final.addBuildInputs prev.cuda_gdb (
    # x86_64 only needs gmp from 12.0 and on
    lib.optionals (cudaVersionAtLeast "12.0") [
      pkgs.gmp
    ]
  );

  cuda_nvcc = prev.cuda_nvcc.overrideAttrs (oldAttrs: {
    propagatedBuildInputs = [
      final.setupCudaHook
    ];

    meta = (oldAttrs.meta or { }) // {
      mainProgram = "nvcc";
    };
  });

  cuda_nvprof = prev.cuda_nvprof.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.addOpenGLRunpath ];
    buildInputs = oldAttrs.buildInputs ++ [ final.cuda_cupti.lib ];
    # libcuda needs to be resolved during runtime
    autoPatchelfIgnoreMissingDeps = ["libcuda.so.1"];
  });

  cuda_demo_suite = final.addBuildInputs prev.cuda_demo_suite [
    pkgs.freeglut
    pkgs.libGLU
    pkgs.libglvnd
    pkgs.mesa
    final.libcufft.lib
    final.libcurand.lib
  ];

  nsight_compute = prev.nsight_compute.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs
    ++ (if (lib.versionOlder prev.nsight_compute.version "2022.2.0")
       then [ pkgs.qt5.wrapQtAppsHook ]
       else [ pkgs.qt6.wrapQtAppsHook ]);
    buildInputs = oldAttrs.buildInputs
    ++ (if (lib.versionOlder prev.nsight_compute.version "2022.2.0")
       then [ pkgs.qt5.qtwebview ]
       else [ pkgs.qt6.qtwebview ]);
  });

  nsight_systems = prev.nsight_systems.overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
      pkgs.addOpenGLRunpath
      pkgs.qt5.wrapQtAppsHook
    ];
    buildInputs = oldAttrs.buildInputs ++ [
      pkgs.alsa-lib
      pkgs.e2fsprogs
      pkgs.nss
      pkgs.numactl
      pkgs.pulseaudio
      pkgs.wayland
      pkgs.xorg.libXcursor
      pkgs.xorg.libXdamage
      pkgs.xorg.libXrandr
      pkgs.xorg.libXtst
    ];
    # libcuda needs to be resolved during runtime
    autoPatchelfIgnoreMissingDeps = true;
  });

  nvidia_driver = prev.nvidia_driver.overrideAttrs (oldAttrs: {
    # libcuda needs to be resolved during runtime
    autoPatchelfIgnoreMissingDeps = ["libcuda.so.1"];
    # No need to support this package as we have drivers already
    # in linuxPackages.
    meta.broken = true;
  });
})
