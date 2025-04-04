{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitLab,
  meson,
  ninja,
  pkg-config,
  python3,
  wayland-scanner,
  wrapGAppsHook3,
  libinput,
  gobject-introspection,
  mutter,
  gnome-desktop,
  glib,
  gtk3,
  json-glib,
  wayland,
  libdrm,
  libxkbcommon,
  wlroots,
  xorg,
  directoryListingUpdater,
  nixosTests,
  testers,
  gmobile,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "phoc";
  version = "0.41.0";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    group = "World";
    owner = "Phosh";
    repo = "phoc";
    rev = "v${finalAttrs.version}";
    hash = "sha256-T2gKvP3WyrGNOiCwiX93UjMuSTnnZ+nykEAFhq0BF4U=";
  };

  nativeBuildInputs = [
    gobject-introspection
    meson
    ninja
    pkg-config
    python3
    wayland-scanner
    wrapGAppsHook3
  ];

  buildInputs = [
    libdrm.dev
    libxkbcommon
    libinput
    glib
    gtk3
    gnome-desktop
    # For keybindings settings schemas
    mutter
    json-glib
    wayland
    finalAttrs.wlroots
    xorg.xcbutilwm
    gmobile
  ];

  mesonFlags = [ "-Dembed-wlroots=disabled" ];

  # Patch wlroots to remove a check which crashes Phosh.
  # This patch can be found within the phoc source tree.
  wlroots = wlroots.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (stdenvNoCC.mkDerivation {
        name = "0001-Revert-layer-shell-error-on-0-dimension-without-anch.patch";
        inherit (finalAttrs) src;
        preferLocalBuild = true;
        allowSubstitutes = false;
        installPhase = "cp subprojects/packagefiles/wlroots/$name $out";
      })
    ];
  });

  passthru = {
    tests.phosh = nixosTests.phosh;
    tests.version = testers.testVersion {
      package = finalAttrs.finalPackage;
    };
    updateScript = directoryListingUpdater { };
  };

  meta = with lib; {
    description = "Wayland compositor for mobile phones like the Librem 5";
    mainProgram = "phoc";
    homepage = "https://gitlab.gnome.org/World/Phosh/phoc";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [
      masipcat
      zhaofengli
    ];
    platforms = platforms.linux;
  };
})
