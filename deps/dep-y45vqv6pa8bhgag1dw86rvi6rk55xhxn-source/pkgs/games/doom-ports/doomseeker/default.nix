{ lib, stdenv, mkDerivation, cmake, fetchFromBitbucket, pkg-config, qtbase, qttools, qtmultimedia, zlib, bzip2, xxd }:

mkDerivation {
  pname = "doomseeker";
  version = "2018-03-05";

  src = fetchFromBitbucket {
    owner = "Doomseeker";
    repo = "doomseeker";
    rev = "c2c7f37b1afb";
    sha256 = "17fna3a604miqsvply3klnmypps4ifz8axgd3pj96z46ybxs8akw";
  };

  patches = [ ./fix_paths.patch ./qt_build_fix.patch ];

  nativeBuildInputs = [ cmake qttools pkg-config xxd ];
  buildInputs = [ qtbase qtmultimedia zlib bzip2 ];

  hardeningDisable = lib.optional stdenv.isDarwin "format";

  meta = with lib; {
    homepage = "http://doomseeker.drdteam.org/";
    description = "Multiplayer server browser for many Doom source ports";
    mainProgram = "doomseeker";
    license = licenses.gpl2;
    platforms = platforms.unix;
    maintainers = [ maintainers.MP2E ];
  };
}
