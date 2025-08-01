{
  lib,
  stdenv,
  fetchFromGitHub,
  substituteAll,
  makeBinaryWrapper,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  vencord,
  electron,
  libicns,
  pipewire,
  libpulseaudio,
  autoPatchelfHook,
  pnpm_10,
  nodejs,
  nix-update-script,
  withTTS ? true,
  withMiddleClickScroll ? false,
  # Enables the use of vencord from nixpkgs instead of
  # letting vesktop manage it's own version
  withSystemVencord ? false,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "vesktop";
  version = "1.5.7";

  src = fetchFromGitHub {
    owner = "Vencord";
    repo = "Vesktop";
    rev = "v${finalAttrs.version}";
    hash = "sha256-2YVaDfvhmuUx2fVm9PuMPQ3Z5iu7IHJ7dgF52a1stoM=";
  };

  pnpmDeps = pnpm_10.fetchDeps {
    inherit (finalAttrs)
      pname
      version
      src
      patches
      ;
    hash = "sha256-C05rDd5bcbR18O6ACgzS0pQdWzB99ulceOBpW+4Zbqw=";
  };

  nativeBuildInputs =
    [
      nodejs
      pnpm_10.configHook
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      # vesktop uses venmic, which is a shipped as a prebuilt node module
      # and needs to be patched
      autoPatchelfHook
      copyDesktopItems
      # we use a script wrapper here for environment variable expansion at runtime
      # https://github.com/NixOS/nixpkgs/issues/172583
      makeWrapper
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      # on macos we don't need to expand variables, so we can use the faster binary wrapper
      makeBinaryWrapper
    ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    libpulseaudio
    pipewire
    (lib.getLib stdenv.cc.cc)
  ];

  patches =
    [
      ./disable_update_checking.patch
      ./fix_read_only_settings.patch
    ]
    ++ lib.optional withSystemVencord (substituteAll {
      inherit vencord;
      src = ./use_system_vencord.patch;
    });

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = 1;
  };

  # disable code signing on macos
  # https://github.com/electron-userland/electron-builder/blob/77f977435c99247d5db395895618b150f5006e8f/docs/code-signing.md#how-to-disable-code-signing-during-the-build-process-on-macos
  postConfigure = lib.optionalString stdenv.hostPlatform.isDarwin ''
    export CSC_IDENTITY_AUTO_DISCOVERY=false
  '';

  # electron builds must be writable on darwin
  preBuild = lib.optionalString stdenv.hostPlatform.isDarwin ''
    cp -r ${electron.dist}/Electron.app .
    chmod -R u+w Electron.app
  '';

  buildPhase = ''
    runHook preBuild

    pnpm build
    pnpm exec electron-builder \
      --dir \
      -c.asarUnpack="**/*.node" \
      -c.electronDist=${if stdenv.hostPlatform.isDarwin then "." else electron.dist} \
      -c.electronVersion=${electron.version}

    runHook postBuild
  '';

  postBuild = lib.optionalString stdenv.hostPlatform.isLinux ''
    pushd build
    ${libicns}/bin/icns2png -x icon.icns
    popd
  '';

  installPhase =
    ''
      runHook preInstall
    ''
    + lib.optionalString stdenv.hostPlatform.isLinux ''
      mkdir -p $out/opt/Vesktop
      cp -r dist/*unpacked/resources $out/opt/Vesktop/

      for file in build/icon_*x32.png; do
        file_suffix=''${file//build\/icon_}
        install -Dm0644 $file $out/share/icons/hicolor/''${file_suffix//x32.png}/apps/vesktop.png
      done
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      mkdir -p $out/{Applications,bin}
      mv dist/mac*/Vesktop.app $out/Applications/Vesktop.app
    ''
    + ''
      runHook postInstall
    '';

  postFixup =
    lib.optionalString stdenv.hostPlatform.isLinux ''
      makeWrapper ${electron}/bin/electron $out/bin/vesktop \
        --add-flags $out/opt/Vesktop/resources/app.asar \
        ${lib.optionalString withTTS "--add-flags \"--enable-speech-dispatcher\""} \
        ${lib.optionalString withMiddleClickScroll "--add-flags \"--enable-blink-features=MiddleClickAutoscroll\""} \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime}}"
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      makeWrapper $out/Applications/Vesktop.app/Contents/MacOS/Vesktop $out/bin/vesktop
    '';

  desktopItems = lib.optional stdenv.hostPlatform.isLinux (makeDesktopItem {
    name = "vesktop";
    desktopName = "Vesktop";
    exec = "vesktop %U";
    icon = "vesktop";
    startupWMClass = "Vesktop";
    genericName = "Internet Messenger";
    keywords = [
      "discord"
      "vencord"
      "electron"
      "chat"
    ];
    categories = [
      "Network"
      "InstantMessaging"
      "Chat"
    ];
  });

  passthru = {
    inherit (finalAttrs) pnpmDeps;
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Alternate client for Discord with Vencord built-in";
    homepage = "https://github.com/Vencord/Vesktop";
    changelog = "https://github.com/Vencord/Vesktop/releases/tag/${finalAttrs.src.rev}";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      getchoo
      Scrumplex
      vgskye
      pluiedev
    ];
    mainProgram = "vesktop";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
