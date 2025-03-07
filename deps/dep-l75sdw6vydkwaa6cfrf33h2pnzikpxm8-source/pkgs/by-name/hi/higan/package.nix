{
  lib,
  SDL2,
  alsa-lib,
  darwin,
  fetchFromGitHub,
  gtk3,
  gtksourceview3,
  libGL,
  libGLU,
  libX11,
  libXv,
  libao,
  libicns,
  libpulseaudio,
  openal,
  pkg-config,
  runtimeShell,
  stdenv,
  udev,
  unstableGitUpdater,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "higan";
  version = "115-unstable-2024-02-17";

  src = fetchFromGitHub {
    owner = "higan-emu";
    repo = "higan";
    rev = "ba4b918c0bbcc302e0d5d2ed70f2c56214d62681";
    hash = "sha256-M8WaPrOPSRKxhYcf6ffNkDzITkCltNF9c/zl0GmfJrI=";
  };

  nativeBuildInputs =
    [
      pkg-config
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      libicns
    ];

  buildInputs =
    [
      SDL2
      libao
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      alsa-lib
      gtk3
      gtksourceview3
      libGL
      libGLU
      libX11
      libXv
      libpulseaudio
      openal
      udev
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin (
      with darwin.apple_sdk.frameworks;
      [
        Carbon
        Cocoa
        OpenAL
        OpenGL
      ]
    );

  patches = [
    # Includes cmath header
    ./001-include-cmath.patch
    # Uses png2icns instead of sips
    ./002-sips-to-png2icns.patch
  ];

  dontConfigure = true;

  enableParallelBuilding = true;

  buildPhase =
    let
      platform =
        if stdenv.hostPlatform.isLinux then
          "linux"
        else if stdenv.hostPlatform.isDarwin then
          "macos"
        else if stdenv.hostPlatform.isBSD then
          "bsd"
        else if stdenv.hostPlatform.isWindows then
          "windows"
        else
          throw "Unknown platform for higan: ${stdenv.hostPlatform.system}";
    in
    ''
      runHook preBuild

      make -C higan-ui -j$NIX_BUILD_CORES \
        compiler=${stdenv.cc.targetPrefix}c++ \
        platform=${platform} \
        openmp=true \
        hiro=gtk3 \
        build=accuracy \
        local=false \
        cores="cv fc gb gba md ms msx ngp pce sfc sg ws"

      make -C icarus -j$NIX_BUILD_CORES \
        compiler=${stdenv.cc.targetPrefix}c++ \
        platform=${platform} \
        openmp=true \
        hiro=gtk3

      runHook postBuild
    '';

  installPhase =
    ''
      runHook preInstall

    ''
    + (
      if stdenv.hostPlatform.isDarwin then
        ''
          mkdir ${placeholder "out"}
          mv higan/out/higan.app ${placeholder "out"}/
          mv icarus/out/icarus.app ${placeholder "out"}/
        ''
      else
        ''
          install -d ${placeholder "out"}/bin
          install higan-ui/out/higan -t ${placeholder "out"}/bin/
          install icarus/out/icarus -t ${placeholder "out"}/bin/

          install -d ${placeholder "out"}/share/applications
          install higan-ui/resource/higan.desktop -t ${placeholder "out"}/share/applications/
          install icarus/resource/icarus.desktop -t ${placeholder "out"}/share/applications/

          install -d ${placeholder "out"}/share/pixmaps
          install higan/higan/resource/higan.svg ${placeholder "out"}/share/pixmaps/higan-icon.svg
          install higan/higan/resource/logo.png ${placeholder "out"}/share/pixmaps/higan-icon.png
          install icarus/resource/icarus.svg ${placeholder "out"}/share/pixmaps/icarus-icon.svg
          install icarus/resource/icarus.png ${placeholder "out"}/share/pixmaps/icarus-icon.png
        ''
    )
    + ''
      install -d ${placeholder "out"}/share/higan
      cp -rd extras/ higan/System/ ${placeholder "out"}/share/higan/

      install -d ${placeholder "out"}/share/icarus
      cp -rd icarus/Database icarus/Firmware ${placeholder "out"}/share/icarus/
    ''
    + (
      # A dirty workaround, suggested by @cpages:
      # we create a first-run script to populate
      # $HOME with all the stuff needed at runtime
      let
        dest =
          if stdenv.hostPlatform.isDarwin then
            "\\$HOME/Library/Application Support/higan"
          else
            "\\$HOME/higan";
      in
      ''
        mkdir -p ${placeholder "out"}/bin
        cat <<EOF > ${placeholder "out"}/bin/higan-init.sh
        #!${runtimeShell}

        cp --recursive --update ${placeholder "out"}/share/higan/System/ "${dest}"/

        EOF

        chmod +x ${placeholder "out"}/bin/higan-init.sh
      ''
    )
    + ''

      runHook postInstall
    '';

  passthru.updateScript = unstableGitUpdater { };

  meta = with lib; {
    homepage = "https://github.com/higan-emu/higan";
    description = "Open-source, cycle-accurate multi-system emulator";
    longDescription = ''
      higan is a multi-system emulator, originally developed by Near, with an
      uncompromising focus on accuracy and code readability.

      It currently emulates the following systems: Famicom, Famicom Disk System,
      Super Famicom, Super Game Boy, Game Boy, Game Boy Color, Game Boy Advance,
      Game Boy Player, SG-1000, SC-3000, Master System, Game Gear, Mega Drive,
      Mega CD, PC Engine, SuperGrafx, MSX, MSX2, ColecoVision, Neo Geo Pocket,
      Neo Geo Pocket Color, WonderSwan, WonderSwan Color, SwanCrystal, Pocket
      Challenge V2.
    '';
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ AndersonTorres ];
    platforms = platforms.unix;
    broken = stdenv.hostPlatform.isDarwin;
  };
})
# TODO: select between Qt and GTK3
