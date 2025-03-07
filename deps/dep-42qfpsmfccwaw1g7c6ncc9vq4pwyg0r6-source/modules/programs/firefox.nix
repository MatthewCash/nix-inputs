{ lib, ... }:
with lib;
let
  modulePath = [ "programs" "firefox" ];

  moduleName = concatStringsSep "." modulePath;

  mkFirefoxModule = import ./firefox/mkFirefoxModule.nix;
in {
  meta.maintainers =
    [ maintainers.rycee hm.maintainers.bricked hm.maintainers.HPsaucii ];

  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = "Firefox";
      wrappedPackageName = "firefox";
      unwrappedPackageName = "firefox-unwrapped";
      visible = true;

      platforms.linux = rec { configPath = ".mozilla/firefox"; };
      platforms.darwin = {
        configPath = "Library/Application Support/Firefox";
      };
    })

    (mkRemovedOptionModule (modulePath ++ [ "extensions" ]) ''
      Extensions are now managed per-profile. That is, change from

        ${moduleName}.extensions = [ foo bar ];

      to

        ${moduleName}.profiles.myprofile.extensions.packages = [ foo bar ];'')
    (mkRemovedOptionModule (modulePath ++ [ "enableAdobeFlash" ])
      "Support for this option has been removed.")
    (mkRemovedOptionModule (modulePath ++ [ "enableGoogleTalk" ])
      "Support for this option has been removed.")
    (mkRemovedOptionModule (modulePath ++ [ "enableIcedTea" ])
      "Support for this option has been removed.")
  ];
}
