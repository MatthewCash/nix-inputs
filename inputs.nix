{
    nixpkgsStable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgsUnstable.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgsUnstable";
    };

    impermanence.url = "github:nix-community/impermanence";

    ragenix = {
        url = "github:yaxitech/ragenix";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    firefox-gnome-theme = {
        url = "github:rafaelmardojai/firefox-gnome-theme/beta";
        flake = false;
    };

    zsh-nix-shell = {
        url = "github:MatthewCash/zsh-nix-shell";
        flake = false;
    };

    nixos-generators = {
        url = "github:nix-community/nixos-generators";
        inputs.nixpkgs.follows = "nixpkgsUnstable";
    };

    aurebesh-fonts = {
        url = "github:MatthewCash/aurebesh-fonts";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    firefox-mods = {
        url = "github:MatthewCash/firefox-mods";
        flake = false;
    };

    tpm-fido = {
        url = "github:MatthewCash/tpm-fido";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    gnome-accent-colors = {
        url = "github:demiskp/custom-accent-colors/v6";
        flake = false;
    };

    lanzaboote = {
        url = "github:nix-community/lanzaboote/v0.3.0";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    mozilla-theme = {
        url = "github:MatthewCash/mozilla-theme";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    kvlibadwaita = {
        url = "github:GabePoel/KvLibadwaita";
        flake = false;
    };

    asus-wmi-screenpad = {
        url = "github:MatthewCash/asus-wmi-screenpad-module";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    codium-theme = {
        url = "github:MatthewCash/codium-theme";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    plasma-manager = {
        url = "github:pjones/plasma-manager";
        inputs.nixpkgs.follows = "nixpkgsUnstable";
    };

    sweet-kde = {
        url = "github:EliverLara/Sweet-kde";
        flake = false;
    };

    nixpak = {
        url = "github:MatthewCash/nixpak";
        inputs.nixpkgs.follows = "nixpkgsUnstable";
    };
}
