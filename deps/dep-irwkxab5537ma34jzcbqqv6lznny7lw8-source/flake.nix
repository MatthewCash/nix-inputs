{
    description = "Owl for Exchange";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";

        original-owl = {
            url = "https://www.beonex.com/owl/owl.xpi";
            flake = false;
        };
    };

    outputs = inputs @ { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
        system: let
            pkgs = nixpkgs.legacyPackages.${system};
            inherit (pkgs) lib;

            licensePatch = builtins.readFile ./license-patch.js;
        in {
            defaultPackage = pkgs.stdenvNoCC.mkDerivation {
                name = "owl-exchange";
                src = inputs.original-owl;
                unpackPhase = ''
                    ${lib.getExe pkgs.unzip} $src
                '';
                patchPhase = ''
                    echo "${licensePatch}" >> license.js
                '';
                dontConfigure = true;
                buildPhase = ''
                    ${lib.getExe pkgs.zip} -r owl.xpi *
                '';
                installPhase = ''
                    mkdir -p $out/addon
                    cp owl.xpi $out/addon/
                '';
            };
        }
    );
}
