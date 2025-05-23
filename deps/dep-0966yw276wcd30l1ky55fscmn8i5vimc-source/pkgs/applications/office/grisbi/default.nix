{
  fetchurl,
  lib,
  stdenv,
  gtk,
  pkg-config,
  libgsf,
  libofx,
  intltool,
  wrapGAppsHook3,
  libsoup,
  adwaita-icon-theme,
}:

stdenv.mkDerivation rec {
  pname = "grisbi";
  version = "2.0.5";

  src = fetchurl {
    url = "mirror://sourceforge/grisbi/${pname}-${version}.tar.bz2";
    sha256 = "sha256-vTrbq/xLTfwF7/YtKzZFiiSw8A0HzzWin2ry8gPHej8=";
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
    intltool
  ];
  buildInputs = [
    gtk
    libgsf
    libofx
    libsoup
    adwaita-icon-theme
  ];

  meta = with lib; {
    description = "Personnal accounting application";
    mainProgram = "grisbi";
    longDescription = ''
      Grisbi is an application written by French developers, so it perfectly
      respects French accounting rules. Grisbi can manage multiple accounts,
      currencies and users. It manages third party, expenditure and receipt
      categories, budgetary lines, financial years, budget estimates, bankcard
      management and other information that make Grisbi adapted for
      associations.
    '';
    homepage = "https://grisbi.org";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ layus ];
    platforms = platforms.linux;
  };
}
