{ lib, stdenv, fetchurl, buildPackages, perl, coreutils, writeShellScript
, makeWrapper
, withCryptodev ? false, cryptodev
, withZlib ? false, zlib
, enableSSL2 ? false
, enableSSL3 ? false
, enableKTLS ? stdenv.isLinux
, static ? stdenv.hostPlatform.isStatic
# path to openssl.cnf file. will be placed in $etc/etc/ssl/openssl.cnf to replace the default
, conf ? null
, removeReferencesTo
, testers
}:

# Note: this package is used for bootstrapping fetchurl, and thus
# cannot use fetchpatch! All mutable patches (generated by GitHub or
# cgit) that are needed here should be included directly in Nixpkgs as
# files.

let
  common = { version, hash, patches ? [], withDocs ? false, extraMeta ? {} }:
   stdenv.mkDerivation (finalAttrs: {
    pname = "openssl";
    inherit version;

    src = fetchurl {
      url = "https://www.openssl.org/source/${finalAttrs.pname}-${version}.tar.gz";
      inherit hash;
    };

    inherit patches;

    postPatch = ''
      patchShebangs Configure
    '' + lib.optionalString (lib.versionOlder version "1.1.1") ''
      patchShebangs test/*
      for a in test/t* ; do
        substituteInPlace "$a" \
          --replace /bin/rm rm
      done
    ''
    # config is a configure script which is not installed.
    + lib.optionalString (lib.versionAtLeast version "1.1.1") ''
      substituteInPlace config --replace '/usr/bin/env' '${buildPackages.coreutils}/bin/env'
    '' + lib.optionalString (lib.versionAtLeast version "1.1.1" && stdenv.hostPlatform.isMusl) ''
      substituteInPlace crypto/async/arch/async_posix.h \
        --replace '!defined(__ANDROID__) && !defined(__OpenBSD__)' \
                  '!defined(__ANDROID__) && !defined(__OpenBSD__) && 0'
    ''
    # Move ENGINESDIR into OPENSSLDIR for static builds, in order to move
    # it to the separate etc output.
    + lib.optionalString static ''
      substituteInPlace Configurations/unix-Makefile.tmpl \
        --replace 'ENGINESDIR=$(libdir)/engines-{- $sover_dirname -}' \
                  'ENGINESDIR=$(OPENSSLDIR)/engines-{- $sover_dirname -}'
    '';

    outputs = [ "bin" "dev" "out" "man" ]
      ++ lib.optional withDocs "doc"
      # Separate output for the runtime dependencies of the static build.
      # Specifically, move OPENSSLDIR into this output, as its path will be
      # compiled into 'libcrypto.a'. This makes it a runtime dependency of
      # any package that statically links openssl, so we want to keep that
      # output minimal.
      ++ lib.optional static "etc";
    setOutputFlags = false;
    separateDebugInfo =
      !stdenv.hostPlatform.isDarwin &&
      !(stdenv.hostPlatform.useLLVM or false) &&
      stdenv.cc.isGNU;

    nativeBuildInputs =
         lib.optional (!stdenv.hostPlatform.isWindows) makeWrapper
      ++ [ perl ]
      ++ lib.optionals static [ removeReferencesTo ];
    buildInputs = lib.optional withCryptodev cryptodev
      ++ lib.optional withZlib zlib;

    # TODO(@Ericson2314): Improve with mass rebuild
    configurePlatforms = [];
    configureScript = {
        armv5tel-linux = "./Configure linux-armv4 -march=armv5te";
        armv6l-linux = "./Configure linux-armv4 -march=armv6";
        armv7l-linux = "./Configure linux-armv4 -march=armv7-a";
        x86_64-darwin  = "./Configure darwin64-x86_64-cc";
        aarch64-darwin = "./Configure darwin64-arm64-cc";
        x86_64-linux = "./Configure linux-x86_64";
        x86_64-solaris = "./Configure solaris64-x86_64-gcc";
        riscv64-linux = "./Configure linux64-riscv64";
      }.${stdenv.hostPlatform.system} or (
        if stdenv.hostPlatform == stdenv.buildPlatform
          then "./config"
        else if stdenv.hostPlatform.isBSD
          then if stdenv.hostPlatform.isx86_64 then "./Configure BSD-x86_64"
          else if stdenv.hostPlatform.isx86_32
            then "./Configure BSD-x86" + lib.optionalString (stdenv.hostPlatform.parsed.kernel.execFormat.name == "elf") "-elf"
          else "./Configure BSD-generic${toString stdenv.hostPlatform.parsed.cpu.bits}"
        else if stdenv.hostPlatform.isMinGW
          then "./Configure mingw${lib.optionalString
                                     (stdenv.hostPlatform.parsed.cpu.bits != 32)
                                     (toString stdenv.hostPlatform.parsed.cpu.bits)}"
        else if stdenv.hostPlatform.isLinux
          then if stdenv.hostPlatform.isx86_64 then "./Configure linux-x86_64"
          else if stdenv.hostPlatform.isMips32 then "./Configure linux-mips32"
          else if stdenv.hostPlatform.isMips64n32 then "./Configure linux-mips64"
          else if stdenv.hostPlatform.isMips64n64 then "./Configure linux64-mips64"
          else "./Configure linux-generic${toString stdenv.hostPlatform.parsed.cpu.bits}"
        else if stdenv.hostPlatform.isiOS
          then "./Configure ios${toString stdenv.hostPlatform.parsed.cpu.bits}-cross"
        else
          throw "Not sure what configuration to use for ${stdenv.hostPlatform.config}"
      );

    # OpenSSL doesn't like the `--enable-static` / `--disable-shared` flags.
    dontAddStaticConfigureFlags = true;
    configureFlags = [
      "shared" # "shared" builds both shared and static libraries
      "--libdir=lib"
      (if !static then
         "--openssldir=etc/ssl"
       else
         # Move OPENSSLDIR to the 'etc' output for static builds. Prepend '/.'
         # to the path to make it appear absolute before variable expansion,
         # else the 'prefix' would be prepended to it.
         "--openssldir=/.$(etc)/etc/ssl"
      )
    ] ++ lib.optionals withCryptodev [
      "-DHAVE_CRYPTODEV"
      "-DUSE_CRYPTODEV_DIGESTS"
    ] ++ lib.optional enableSSL2 "enable-ssl2"
      ++ lib.optional enableSSL3 "enable-ssl3"
      # We select KTLS here instead of the configure-time detection (which we patch out).
      # KTLS should work on FreeBSD 13+ as well, so we could enable it if someone tests it.
      ++ lib.optional (lib.versionAtLeast version "3.0.0" && enableKTLS) "enable-ktls"
      ++ lib.optional (lib.versionAtLeast version "1.1.1" && stdenv.hostPlatform.isAarch64) "no-afalgeng"
      # OpenSSL needs a specific `no-shared` configure flag.
      # See https://wiki.openssl.org/index.php/Compilation_and_Installation#Configure_Options
      # for a comprehensive list of configuration options.
      ++ lib.optional (lib.versionAtLeast version "1.1.1" && static) "no-shared"
      ++ lib.optional (lib.versionAtLeast version "3.0.0" && static) "no-module"
      # This introduces a reference to the CTLOG_FILE which is undesired when
      # trying to build binaries statically.
      ++ lib.optional static "no-ct"
      ++ lib.optional withZlib "zlib"
      ++ lib.optionals (stdenv.hostPlatform.isMips && stdenv.hostPlatform ? gcc.arch) [
      # This is necessary in order to avoid openssl adding -march
      # flags which ultimately conflict with those added by
      # cc-wrapper.  Openssl assumes that it can scan CFLAGS to
      # detect any -march flags, using this perl code:
      #
      #   && !grep { $_ =~ /-m(ips|arch=)/ } (@{$config{CFLAGS}})
      #
      # The following bogus CFLAGS environment variable triggers the
      # the code above, inhibiting `./Configure` from adding the
      # conflicting flags.
      "CFLAGS=-march=${stdenv.hostPlatform.gcc.arch}"
    ];

    makeFlags = [
      "MANDIR=$(man)/share/man"
      # This avoids conflicts between man pages of openssl subcommands (for
      # example 'ts' and 'err') man pages and their equivalent top-level
      # command in other packages (respectively man-pages and moreutils).
      # This is done in ubuntu and archlinux, and possiibly many other distros.
      "MANSUFFIX=ssl"
    ];

    enableParallelBuilding = true;

    postInstall =
    (if static then ''
      # OPENSSLDIR has a reference to self
      remove-references-to -t $out $out/lib/*.a
    '' else ''
      # If we're building dynamic libraries, then don't install static
      # libraries.
      if [ -n "$(echo $out/lib/*.so $out/lib/*.dylib $out/lib/*.dll)" ]; then
          rm "$out/lib/"*.a
      fi

      # 'etc' is a separate output on static builds only.
      etc=$out
    '') + ''
      mkdir -p $bin
      mv $out/bin $bin/bin

    '' + lib.optionalString (!stdenv.hostPlatform.isWindows)
      # makeWrapper is broken for windows cross (https://github.com/NixOS/nixpkgs/issues/120726)
    ''
      # c_rehash is a legacy perl script with the same functionality
      # as `openssl rehash`
      # this wrapper script is created to maintain backwards compatibility without
      # depending on perl
      makeWrapper $bin/bin/openssl $bin/bin/c_rehash \
        --add-flags "rehash"
    '' + ''

      mkdir $dev
      mv $out/include $dev/

      # remove dependency on Perl at runtime
      rm -r $etc/etc/ssl/misc

      rmdir $etc/etc/ssl/{certs,private}

      ${lib.optionalString (conf != null) "cat ${conf} > $etc/etc/ssl/openssl.cnf"}
    '';

    postFixup = lib.optionalString (!stdenv.hostPlatform.isWindows) ''
      # Check to make sure the main output and the static runtime dependencies
      # don't depend on perl
      if grep -r '${buildPackages.perl}' $out $etc; then
        echo "Found an erroneous dependency on perl ^^^" >&2
        exit 1
      fi
    '';

    passthru.tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;

    meta = with lib; {
      homepage = "https://www.openssl.org/";
      changelog = "https://github.com/openssl/openssl/blob/openssl-${version}/CHANGES.md";
      description = "A cryptographic library that implements the SSL and TLS protocols";
      license = licenses.openssl;
      mainProgram = "openssl";
      maintainers = with maintainers; [ thillux ];
      pkgConfigModules = [
        "libcrypto"
        "libssl"
        "openssl"
      ];
      platforms = platforms.all;
    } // extraMeta;
  });

in {

  # If you do upgrade here, please update in pkgs/top-level/release.nix
  # the permitted insecure version to ensure it gets cached for our users
  # and backport this to stable release (23.05).
  openssl_1_1 = common {
    version = "1.1.1w";
    hash = "sha256-zzCYlQy02FOtlcCEHx+cbT3BAtzPys1SHZOSUgi3asg=";
    patches = [
      ./1.1/nix-ssl-cert-file.patch

      (if stdenv.hostPlatform.isDarwin
       then ./use-etc-ssl-certs-darwin.patch
       else ./use-etc-ssl-certs.patch)
    ];
    withDocs = true;
    extraMeta = {
      knownVulnerabilities = [
        "OpenSSL 1.1 is reaching its end of life on 2023/09/11 and cannot be supported through the NixOS 23.05 release cycle. https://www.openssl.org/blog/blog/2023/03/28/1.1.1-EOL/"
      ];
    };
  };

  openssl_3 = common {
    version = "3.0.13";
    hash = "sha256-iFJXU/edO+wn0vp8ZqoLkrOqlJja/ZPXz6SzeAza4xM=";

    patches = [
      ./3.0/nix-ssl-cert-file.patch

      # openssl will only compile in KTLS if the current kernel supports it.
      # This patch disables build-time detection.
      ./3.0/openssl-disable-kernel-detection.patch

      (if stdenv.hostPlatform.isDarwin
       then ./use-etc-ssl-certs-darwin.patch
       else ./use-etc-ssl-certs.patch)
    ];

    withDocs = true;

    extraMeta = with lib; {
      license = licenses.asl20;
    };
  };

  openssl_3_1 = common {
    version = "3.1.5";
    hash = "sha256-auAVRn2r8EabE5rakzGTJ74kuYJR/67O2gIhhI3AkmI=";

    patches = [
      ./3.0/nix-ssl-cert-file.patch

      # openssl will only compile in KTLS if the current kernel supports it.
      # This patch disables build-time detection.
      ./3.0/openssl-disable-kernel-detection.patch

      (if stdenv.hostPlatform.isDarwin
       then ./use-etc-ssl-certs-darwin.patch
       else ./use-etc-ssl-certs.patch)
    ];

    withDocs = true;

    extraMeta = with lib; {
      license = licenses.asl20;
    };
  };
}
