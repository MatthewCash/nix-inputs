{
  stdenv,
  lib,
  buildMozillaMach,
  callPackage,
  fetchurl,
  icu73,
  icu76,
  fetchpatch2,
  config,
}:

let
  patchICU =
    icu:
    icu.overrideAttrs (attrs: {
      # standardize vtzone output
      # Work around ICU-22132 https://unicode-org.atlassian.net/browse/ICU-22132
      # https://bugzilla.mozilla.org/show_bug.cgi?id=1790071
      patches = attrs.patches ++ [
        (fetchpatch2 {
          url = "https://hg.mozilla.org/mozilla-central/raw-file/fb8582f80c558000436922fb37572adcd4efeafc/intl/icu-patches/bug-1790071-ICU-22132-standardize-vtzone-output.diff";
          stripLen = 3;
          hash = "sha256-MGNnWix+kDNtLuACrrONDNcFxzjlUcLhesxwVZFzPAM=";
        })
      ];
    });
  icu73' = patchICU icu73;
  icu76' = patchICU icu76;

  common =
    {
      version,
      sha512,
      updateScript,
    }:
    (buildMozillaMach rec {
      pname = "thunderbird";
      inherit version updateScript;
      application = "comm/mail";
      applicationName = "Mozilla Thunderbird";
      binaryName = pname;
      src = fetchurl {
        url = "mirror://mozilla/thunderbird/releases/${version}/source/thunderbird-${version}.source.tar.xz";
        inherit sha512;
      };
      extraPatches = [
        # The file to be patched is different from firefox's `no-buildconfig-ffx90.patch`.
        ./no-buildconfig.patch
      ];

      extraPassthru = {
        icu73 = icu73';
        icu76 = icu76';
      };

      meta = with lib; {
        changelog = "https://www.thunderbird.net/en-US/thunderbird/${version}/releasenotes/";
        description = "Full-featured e-mail client";
        homepage = "https://thunderbird.net/";
        mainProgram = "thunderbird";
        maintainers = with maintainers; [
          lovesegfault
          pierron
          vcunat
        ];
        platforms = platforms.unix;
        badPlatforms = platforms.darwin;
        broken = stdenv.buildPlatform.is32bit;
        # since Firefox 60, build on 32-bit platforms fails with "out of memory".
        # not in `badPlatforms` because cross-compilation on 64-bit machine might work.
        license = licenses.mpl20;
      };
    }).override
      {
        geolocationSupport = false;
        webrtcSupport = false;

        pgoSupport = false; # console.warn: feeds: "downloadFeed: network connection unavailable"

        icu73 = icu73';
        icu76 = icu76';
      };

in
rec {
  # Upstream claims -latest is "for testing purposes only". Stick to -esr until this changes.
  thunderbird = thunderbird-esr;

  thunderbird-latest = common {
    version = "138.0";
    sha512 = "923d76cf0a14f29146e5dcfc75dd9522d465512f6c604de6e0acc0812d4240331c170913a821fc0aa03d5945019577f996053498c9a7c691b21a2678a622ac02";

    updateScript = callPackage ./update.nix {
      attrPath = "thunderbirdPackages.thunderbird-latest";
    };
  };

  # Eventually, switch to an updateScript without versionPrefix hardcoded...
  thunderbird-esr = thunderbird-128;

  thunderbird-128 = common {
    version = "128.10.0esr";
    sha512 = "b02582ea4fa0297a06d30eda1555bbf3ed79ae7a35a8993f2a70b0ec84af28a4d084cd7ebe1c73676e689ff9366e779cc5ef67a197638949bf232a40b740d1b6";

    updateScript = callPackage ./update.nix {
      attrPath = "thunderbirdPackages.thunderbird-128";
      versionPrefix = "128";
      versionSuffix = "esr";
    };
  };
}
// lib.optionalAttrs config.allowAliases {
  thunderbird-102 = throw "Thunderbird 102 support ended in September 2023";
  thunderbird-115 = throw "Thunderbird 115 support ended in October 2024";
}
