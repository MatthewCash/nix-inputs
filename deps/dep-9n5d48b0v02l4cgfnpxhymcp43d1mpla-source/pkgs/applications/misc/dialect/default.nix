{ lib
, fetchFromGitHub
, wrapGAppsHook4
, python3
, appstream-glib
, blueprint-compiler
, desktop-file-utils
, meson
, ninja
, pkg-config
, glib
, gtk4
, gobject-introspection
, gst_all_1
, libsoup_3
, libadwaita
}:

python3.pkgs.buildPythonApplication rec {
  pname = "dialect";
  version = "2.0.1";

  format = "other";

  src = fetchFromGitHub {
    owner = "dialect-app";
    repo = pname;
    rev = version;
    fetchSubmodules = true;
    hash = "sha256-Ke23QnvKpmyuaqkiBQL1cUa0T7lSfYPLFi6wa9G8LYk=";
  };

  nativeBuildInputs = [
    appstream-glib
    blueprint-compiler
    desktop-file-utils
    gobject-introspection
    meson
    ninja
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    glib
    gobject-introspection
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    libsoup_3
    libadwaita
  ];

  propagatedBuildInputs = with python3.pkgs; [
    dbus-python
    gtts
    pygobject3
  ];

  # Prevent double wrapping, let the Python wrapper use the args in preFixup.
  dontWrapGApps = true;

  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  doCheck = false;

  # handle setup hooks better
  strictDeps = false;

  meta = with lib; {
    homepage = "https://github.com/dialect-app/dialect";
    description = "A translation app for GNOME";
    maintainers = with maintainers; [ linsui ];
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
