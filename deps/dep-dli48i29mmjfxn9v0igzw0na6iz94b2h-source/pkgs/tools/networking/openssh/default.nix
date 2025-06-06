{
  callPackage,
  lib,
  fetchurl,
  fetchpatch,
  autoreconfHook,
}:
let
  common = opts: callPackage (import ./common.nix opts) { };

  # https://github.com/advisories/GHSA-26mg-p594-q328
  fix-cve-2025-32738 = fetchpatch {
    name = "fix-cve-2025-32738.patch";
    url = "https://ftp.openbsd.org/pub/OpenBSD/patches/7.6/common/013_ssh.patch.sig";
    hash = "sha256-YF8tda2lYrSeKEp0KPqu/QHcR1rMKRnhu+Tpb8DeX9I=";
    stripLen = 1;
  };
in
{
  openssh = common rec {
    pname = "openssh";
    version = "9.9p2";

    src = fetchurl {
      url = "mirror://openbsd/OpenSSH/portable/openssh-${version}.tar.gz";
      hash = "sha256-karbYD4IzChe3fll4RmdAlhfqU2ZTWyuW0Hhch4hVnM=";
    };

    extraPatches = [
      ./ssh-keysign-8.5.patch
      fix-cve-2025-32738
    ];
    extraMeta.maintainers = lib.teams.helsinki-systems.members;
  };

  openssh_hpn = common rec {
    pname = "openssh-with-hpn";
    version = "9.9p2";
    extraDesc = " with high performance networking patches";

    src = fetchurl {
      url = "mirror://openbsd/OpenSSH/portable/openssh-${version}.tar.gz";
      hash = "sha256-karbYD4IzChe3fll4RmdAlhfqU2ZTWyuW0Hhch4hVnM=";
    };

    extraPatches =
      let
        url = "https://raw.githubusercontent.com/freebsd/freebsd-ports/7ba88c964b6e5724eec462021d984da3989e6a08/security/openssh-portable/files/extra-patch-hpn";
      in
      [
        ./ssh-keysign-8.5.patch
        fix-cve-2025-32738

        # HPN Patch from FreeBSD ports
        (fetchpatch {
          name = "ssh-hpn-wo-channels.patch";
          inherit url;
          stripLen = 1;
          excludes = [ "channels.c" ];
          hash = "sha256-zk7t6FNzTE+8aDU4QuteR1x0W3O2gjIQmeCkTNbaUfA=";
        })

        (fetchpatch {
          name = "ssh-hpn-channels.patch";
          inherit url;
          extraPrefix = "";
          includes = [ "channels.c" ];
          hash = "sha256-pDLUbjv5XIyByEbiRAXC3WMUPKmn15af1stVmcvr7fE=";
        })
      ];

    extraNativeBuildInputs = [ autoreconfHook ];

    extraConfigureFlags = [ "--with-hpn" ];
    extraMeta = {
      maintainers = with lib.maintainers; [ abbe ];
    };
  };

  openssh_gssapi = common rec {
    pname = "openssh-with-gssapi";
    version = "9.9p2";
    extraDesc = " with GSSAPI support";

    src = fetchurl {
      url = "mirror://openbsd/OpenSSH/portable/openssh-${version}.tar.gz";
      hash = "sha256-karbYD4IzChe3fll4RmdAlhfqU2ZTWyuW0Hhch4hVnM=";
    };

    extraPatches = [
      ./ssh-keysign-8.5.patch
      fix-cve-2025-32738

      (fetchpatch {
        name = "openssh-gssapi.patch";
        url = "https://salsa.debian.org/ssh-team/openssh/raw/debian/1%25${version}-1/debian/patches/gssapi.patch";
        hash = "sha256-JyOXA8Al8IFLdndJQ1LO+r4hJqtXjz1NHwOPiSAQkE8=";
      })
    ];

    extraNativeBuildInputs = [ autoreconfHook ];
  };
}
