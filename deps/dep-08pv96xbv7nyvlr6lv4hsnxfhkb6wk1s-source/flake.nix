{
    description = "Aurebesh Fonts";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
        
        aurabesh = {
            url = "https://github.com/AurekFonts/AurekFonts.github.io/raw/master/AurebeshAF/AurebeshAF-Legends.otf";
            flake = false;
        };
    };

    outputs = inputs @ { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
            defaultPackage = pkgs.stdenvNoCC.mkDerivation {
                name = "aurebesh-font";
                src = inputs.aurabesh;
                dontUnpack = true;
                dontConfigure = true;
                installPhase = ''
                    local out_ttf=$out/share/fonts/opentype
                    install -m444 -D $src $out_ttf/aurebesh.otf
                '';
            };
        }
    );
}
