{
  lib,
  config,
  stdenv,
  nixDependencies,
  generateSplicesForMkScope,
  fetchFromGitHub,
  fetchpatch,
  fetchpatch2,
  runCommand,
  buildPackages,
  Security,
  pkgs,
  pkgsi686Linux,
  pkgsStatic,
  nixosTests,

  storeDir ? "/nix/store",
  stateDir ? "/nix/var",
  confDir ? "/etc",
}:
let

  # Called for Nix < 2.26
  commonAutoconf =
    args:
    nixDependencies.callPackage
      (import ./common-autoconf.nix ({ inherit lib fetchFromGitHub; } // args))
      {
        inherit
          Security
          storeDir
          stateDir
          confDir
          ;
        boehmgc = nixDependencies.boehmgc-coroutine-patch;
        aws-sdk-cpp =
          if lib.versionAtLeast args.version "2.12pre" then
            nixDependencies.aws-sdk-cpp
          else
            nixDependencies.aws-sdk-cpp-old;
        libgit2 =
          if lib.versionAtLeast args.version "2.25.0" then
            nixDependencies.libgit2-thin-packfile
          else
            pkgs.libgit2;
      };

  # Called for Nix == 2.28. Transitional until we always use
  # per-component packages.
  commonMeson =
    args:
    nixDependencies.callPackage (import ./common-meson.nix ({ inherit lib fetchFromGitHub; } // args)) {
      inherit
        Security
        storeDir
        stateDir
        confDir
        ;
      libgit2 =
        if lib.versionAtLeast args.version "2.25.0" then
          nixDependencies.libgit2-thin-packfile
        else
          pkgs.libgit2;
    };

  # https://github.com/NixOS/nix/pull/7585
  patch-monitorfdhup = fetchpatch2 {
    name = "nix-7585-monitor-fd-hup.patch";
    url = "https://github.com/NixOS/nix/commit/1df3d62c769dc68c279e89f68fdd3723ed3bcb5a.patch";
    hash = "sha256-f+F0fUO+bqyPXjt+IXJtISVr589hdc3y+Cdrxznb+Nk=";
  };

  # Intentionally does not support overrideAttrs etc
  # Use only for tests that are about the package relation to `pkgs` and/or NixOS.
  addTestsShallowly =
    tests: pkg:
    pkg
    // {
      tests = pkg.tests // tests;
      # In case someone reads the wrong attribute
      passthru.tests = pkg.tests // tests;
    };

  addFallbackPathsCheck =
    pkg:
    addTestsShallowly {
      nix-fallback-paths =
        runCommand "test-nix-fallback-paths-version-equals-nix-stable"
          {
            paths = lib.concatStringsSep "\n" (
              builtins.attrValues (import ../../../../nixos/modules/installer/tools/nix-fallback-paths.nix)
            );
          }
          ''
            # NOTE: name may contain cross compilation details between the pname
            #       and version this is permitted thanks to ([^-]*-)*
            if [[ "" != $(grep -vE 'nix-([^-]*-)*${
              lib.strings.replaceStrings [ "." ] [ "\\." ] pkg.version
            }$' <<< "$paths") ]]; then
              echo "nix-fallback-paths not up to date with nixVersions.stable (nix-${pkg.version})"
              echo "The following paths are not up to date:"
              grep -v 'nix-${pkg.version}$' <<< "$paths"
              echo
              echo "Fix it by running in nixpkgs:"
              echo
              echo "curl https://releases.nixos.org/nix/nix-${pkg.version}/fallback-paths.nix >nixos/modules/installer/tools/nix-fallback-paths.nix"
              echo
              exit 1
            else
              echo "nix-fallback-paths versions up to date"
              touch $out
            fi
          '';
    } pkg;

  # (meson based packaging)
  # Add passthru tests to the package, and re-expose package set overriding
  # functions. This will not incorporate the tests into the package set.
  # TODO (roberth): add package-set level overriding to the "everything" package.
  addTests =
    selfAttributeName: pkg:
    let
      tests =
        pkg.tests or { }
        // import ./tests.nix {
          inherit
            runCommand
            lib
            stdenv
            pkgs
            pkgsi686Linux
            pkgsStatic
            nixosTests
            ;
          inherit (pkg) version src;
          nix = pkg;
          self_attribute_name = selfAttributeName;
        };
    in
    # preserve old pkg, including overrideSource, etc
    pkg
    // {
      tests = pkg.tests or { } // tests;
      passthru = pkg.passthru or { } // {
        tests =
          lib.warn "nix.passthru.tests is deprecated. Use nix.tests instead." pkg.passthru.tests or { }
          // tests;
      };
    };

  # Factored out for when we have package sets for multiple versions of
  # Nix.
  #
  # `nixPackages_*` would be the most regular name, analogous to
  # `linuxPackages_*`, especially if we put other 3rd-party software in
  # here, but `nixPackages_*` would also be *very* confusing to humans!
  generateSplicesForNixComponents =
    nixComponentsAttributeName:
    generateSplicesForMkScope [
      "nixVersions"
      nixComponentsAttributeName
    ];

in
lib.makeExtensible (
  self:
  (
    {
      nix_2_3 =
        (
          (commonAutoconf {
            version = "2.3.18";
            hash = "sha256-jBz2Ub65eFYG+aWgSI3AJYvLSghio77fWQiIW1svA9U=";
            patches = [
              patch-monitorfdhup
            ];
            self_attribute_name = "nix_2_3";
            maintainers = with lib.maintainers; [ flokli ];
          }).override
          { boehmgc = nixDependencies.boehmgc-no-coroutine-patch; }
        ).overrideAttrs
          {
            # https://github.com/NixOS/nix/issues/10222
            # spurious test/add.sh failures
            enableParallelChecking = false;
          };

      nix_2_18 = commonAutoconf {
        version = "2.18.9";
        hash = "sha256-RrOFlDGmRXcVRV2p2HqHGqvzGNyWoD0Dado/BNlJ1SI=";
        self_attribute_name = "nix_2_18";
      };

      nix_2_19 = commonAutoconf {
        version = "2.19.7";
        hash = "sha256-CkT1SNwRYYQdN2X4cTt1WX3YZfKZFWf7O1YTEo1APfc=";
        self_attribute_name = "nix_2_19";
      };

      nix_2_20 = commonAutoconf {
        version = "2.20.9";
        hash = "sha256-b7smrbPLP/wcoBFCJ8j1UDNj0p4jiKT/6mNlDdlrOXA=";
        self_attribute_name = "nix_2_20";
      };

      nix_2_21 = commonAutoconf {
        version = "2.21.5";
        hash = "sha256-/+TLpd6hvYMJFoeJvVZ+bZzjwY/jP6CxJRGmwKcXbI0=";
        self_attribute_name = "nix_2_21";
      };

      nix_2_22 = commonAutoconf {
        version = "2.22.4";
        hash = "sha256-JWjJzMA+CeyImMgP2dhSBHQW4CS8wg7fc2zQ4WdKuBo=";
        self_attribute_name = "nix_2_22";
      };

      nix_2_23 = commonAutoconf {
        version = "2.23.4";
        hash = "sha256-rugH4TUicHEdVfy3UuAobFIutqbuVco8Yg/z81g7clE=";
        self_attribute_name = "nix_2_23";
      };

      nix_2_24 = commonAutoconf {
        version = "2.24.14";
        hash = "sha256-SthMCsj6POjawLnJq9+lj/UzObX9skaeN1UGmMZiwTY=";
        patches = [ ./patches/ghsa-g948-229j-48j3-2.24.patch ];
        self_attribute_name = "nix_2_24";
      };

      nix_2_25 = commonAutoconf {
        version = "2.25.5";
        hash = "sha256-9xrQhrqHCSqWsQveykZvG/ZMu0se66fUQw3xVSg6BpQ=";
        self_attribute_name = "nix_2_25";
      };

      nix_2_26 = commonMeson {
        version = "2.26.4";
        hash = "sha256-WmGMiwwC9RLomNtpDeRoe5bqBAH84A6pLcqi1MbcQi4=";
        self_attribute_name = "nix_2_26";
      };

      nix_2_28 = commonMeson {
        version = "2.28.2";
        hash = "sha256-yl+hlZ/VFHIZwPIDEs4ysOYgprW4VEORfSyvScF7Cwg=";
        self_attribute_name = "nix_2_28";
        patches = [
          # fixes user/system registries regression: https://github.com/NixOS/nix/issues/13050
          ./patches/0001-Revert-Actually-ignore-system-user-registries-during.patch
          ./patches/ghsa-g948-229j-48j3-2.28.patch
        ];
      };

      nixComponents_git = nixDependencies.callPackage ./modular/packages.nix rec {
        version = "2.30pre20250521_${lib.substring 0 8 src.rev}";
        inherit (self.nix_2_24.meta) maintainers;
        otherSplices = generateSplicesForNixComponents "nixComponents_git";
        src = fetchFromGitHub {
          owner = "NixOS";
          repo = "nix";
          rev = "76a4d4c2913a1654dddd195b034ff7e66cb3e96f";
          hash = "sha256-OA22Ig72oV6reHN8HMlimmnrsxpNzqyzi4h6YBVzzEA=";
        };
      };

      git = addTests "git" self.nixComponents_git.nix-everything;

      latest = self.nix_2_24;

      # The minimum Nix version supported by Nixpkgs
      # Note that some functionality *might* have been backported into this Nix version,
      # making this package an inaccurate representation of what features are available
      # in the actual lowest minver.nix *patch* version.
      minimum =
        let
          minver = import ../../../../lib/minver.nix;
          major = lib.versions.major minver;
          minor = lib.versions.minor minver;
          attribute = "nix_${major}_${minor}";
          nix = self.${attribute};
        in
        if !self ? ${attribute} then
          throw "The minimum supported Nix version is ${minver} (declared in lib/minver.nix), but pkgs.nixVersions.${attribute} does not exist."
        else
          nix;

      # Read ./README.md before bumping a major release
      stable = addFallbackPathsCheck self.nix_2_24;
    }
    // lib.optionalAttrs config.allowAliases (
      lib.listToAttrs (
        map (
          minor:
          let
            attr = "nix_2_${toString minor}";
          in
          lib.nameValuePair attr (throw "${attr} has been removed")
        ) (lib.range 4 17)
      )
      // {
        nixComponents_2_27 = throw "nixComponents_2_27 has been removed. use nixComponents_git.";
        nix_2_27 = throw "nix_2_27 has been removed. use nix_2_28.";

        unstable = throw "nixVersions.unstable has been removed. For bleeding edge (Nix master, roughly weekly updated) use nixVersions.git, otherwise use nixVersions.latest.";
      }
    )
  )
)
