{
    asus-wmi-screenpad = {
        url = "github:MatthewCash/asus-wmi-screenpad-module";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    aurebesh-fonts = {
        url = "github:MatthewCash/aurebesh-fonts";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    codium-theme = {
        url = "github:MatthewCash/codium-theme";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    firefox-gnome-theme = {
        url = "github:rafaelmardojai/firefox-gnome-theme/beta";
        flake = false;
    };

    firefox-mods = {
        url = "github:MatthewCash/firefox-mods";
        flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";

    gnome-accent-colors = {
        url = "github:demiskp/custom-accent-colors/v6";
        flake = false;
    };

    home-manager = {
        url = "github:nix-community/home-manager";
        inputs.nixpkgs.follows = "nixpkgsUnstable";
    };

    impermanence.url = "github:nix-community/impermanence";

    kvlibadwaita = {
        url = "github:GabePoel/KvLibadwaita";
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

    nixos-generators = {
        url = "github:nix-community/nixos-generators";
        inputs.nixpkgs.follows = "nixpkgsUnstable";
    };

    nixpkgsStable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgsUnstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpak = {
        url = "github:MatthewCash/nixpak";
        inputs.nixpkgs.follows = "nixpkgsUnstable";
    };

    owl-patched = {
        url = "github:MatthewCash/owl-patched";
        inputs.nixpkgs.follows = "nixpkgsUnstable";
    };

    plasma-manager = {
        url = "github:pjones/plasma-manager";
        inputs.nixpkgs.follows = "nixpkgsUnstable";
    };

    ragenix = {
        url = "github:yaxitech/ragenix";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    sweet-kde = {
        url = "github:EliverLara/Sweet-kde";
        flake = false;
    };

    tpm-fido = {
        url = "github:MatthewCash/tpm-fido";
        inputs.nixpkgs.follows = "nixpkgsStable";
    };

    zsh-nix-shell = {
        url = "github:MatthewCash/zsh-nix-shell";
        flake = false;
    };
}
