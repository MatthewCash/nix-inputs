{
    description = "Theme for Mozilla Software";

    inputs = {
        nixpkgs.url = "nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
            defaultPackage = pkgs.lib.makeOverridable ({ accentColor }: pkgs.stdenvNoCC.mkDerivation {
                name = "mozilla-theme";
                src = ./src;
                dontConfigure = true;
                unpackPhase = ''
                    cp $src/manifest.json .
                '';
                patchPhase = let
                    h = builtins.toString accentColor.h;
                    s = builtins.toString accentColor.s;
                    l = builtins.toString accentColor.l;
                    hsl = "hsl(${h},${s}%,${l}%)";
                in ''
                    substituteInPlace manifest.json --replace "{{ACCENTCOLOR}}" "${hsl}"
                '';
                buildPhase = ''
                    ${pkgs.p7zip}/bin/7z a theme.xpi *
                '';
                installPhase = ''
                    mkdir -p $out/addon
                    cp theme.xpi $out/addon/
                '';
            }) { accentColor = { h = 300; s = 60; l = 70; }; };
        }
    );
}
