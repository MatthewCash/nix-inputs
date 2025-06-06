{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  nix-update-script,
  substituteAll,
  meson,
  ninja,
  python3,
  pkg-config,
  vala,
  granite,
  libgee,
  gettext,
  gtk3,
  json-glib,
  elementary-dock,
  bamf,
  switchboard-with-plugs,
  libsoup,
  wingpanel,
  zeitgeist,
  bc,
  libhandy,
}:

stdenv.mkDerivation rec {
  pname = "wingpanel-applications-menu";
  version = "2.11.1";

  src = fetchFromGitHub {
    owner = "elementary";
    repo = "applications-menu";
    rev = version;
    sha256 = "sha256-WlRrEkX0DGIHYWvUc9G4BbvofzWJwqkiJaJFwQ43GPE=";
  };

  patches = [
    (substituteAll {
      src = ./fix-paths.patch;
      bc = "${bc}/bin/bc";
    })

    # Build against switchboard-3
    # https://github.com/elementary/applications-menu/pull/580
    (fetchpatch {
      url = "https://github.com/elementary/applications-menu/commit/9191ee5a2ee33477515d331b96945d51a13074a9.patch";
      excludes = [ ".github/workflows/githubci.yml" ];
      hash = "sha256-/LOIEOg9fVfKv/BWFsP1VyuUOIFYem9Gk+3e49M2b9E=";
    })
  ];

  nativeBuildInputs = [
    gettext
    meson
    ninja
    pkg-config
    python3
    vala
  ];

  buildInputs =
    [
      bamf
      elementary-dock
      granite
      gtk3
      json-glib
      libgee
      libhandy
      libsoup
      switchboard-with-plugs
      wingpanel
      zeitgeist
    ]
    ++
    # applications-menu has a plugin to search switchboard plugins
    # see https://github.com/NixOS/nixpkgs/issues/100209
    # wingpanel's wrapper will need to pick up the fact that
    # applications-menu needs a version of switchboard with all
    # its plugins for search.
    switchboard-with-plugs.buildInputs;

  mesonFlags = [
    "--sysconfdir=${placeholder "out"}/etc"
  ];

  postPatch = ''
    chmod +x meson/post_install.py
    patchShebangs meson/post_install.py
  '';

  doCheck = true;

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "Lightweight and stylish app launcher for Pantheon";
    homepage = "https://github.com/elementary/applications-menu";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = teams.pantheon.members;
  };
}
