{
  lib,
  stdenv,
  rustPlatform,
  cargo,
  rustc,
  fetchFromGitLab,
  gtk4,
  libadwaita,
  openssl,
  meson,
  ninja,
  pkg-config,
  wrapGAppsHook4,
  glib,
  appstream-glib,
  desktop-file-utils,
  blueprint-compiler,
  sqlite,
  clapper-unwrapped,
  gettext,
  gst_all_1,
  gtuber,
  glib-networking,
  gnome,
  webp-pixbuf-loader,
  librsvg,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pipeline";
  version = "2.6.1";

  src = fetchFromGitLab {
    owner = "schmiddi-on-mobile";
    repo = "pipeline";
    rev = finalAttrs.version;
    hash = "sha256-0g8J65dQoxOmdDdZHn7O1FB8fL2EdfuhbFO1VG0UCtE=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src;
    hash = "sha256-c9bjAc6ozCJ1l+SeR9LoQmk/wKQEXAZy0+c1+vGoE9U=";
  };

  nativeBuildInputs = [
    meson
    ninja
    cargo
    rustPlatform.cargoSetupHook
    rustc
    pkg-config
    wrapGAppsHook4
    glib
    appstream-glib
    desktop-file-utils
    blueprint-compiler
  ];

  buildInputs = [
    gtk4
    libadwaita
    openssl
    sqlite
    clapper-unwrapped

    gst_all_1.gstreamer
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-base
    (gst_all_1.gst-plugins-good.override { gtkSupport = true; })
    gst_all_1.gst-plugins-bad
    gettext
    gtuber
    glib-networking # For GIO_EXTRA_MODULES. Fixes "TLS support is not available"
  ];

  # Pull in WebP support for YouTube avatars.
  # In postInstall to run before gappsWrapperArgsHook.
  postInstall = ''
    export GDK_PIXBUF_MODULE_FILE="${
      gnome._gdkPixbufCacheBuilder_DO_NOT_USE {
        extraLoaders = [
          webp-pixbuf-loader
          librsvg
        ];
      }
    }"
  '';

  passthru.updateScript = nix-update-script { attrPath = finalAttrs.pname; };

  meta = {
    description = "Watch YouTube and PeerTube videos in one place";
    homepage = "https://mobile.schmidhuberj.de/pipeline";
    mainProgram = "tubefeeder";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ chuangzhu ];
    platforms = lib.platforms.linux;
  };
})
