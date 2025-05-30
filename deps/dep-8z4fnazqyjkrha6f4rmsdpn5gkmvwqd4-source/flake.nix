{
    description = "FIDO token implementation that protects token keys using TPM";

    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    inputs.flake-utils.url = "github:numtide/flake-utils";

    outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
        let
            pkgs = import nixpkgs {
                inherit system;
            };
        in {
            packages.default =pkgs.buildGoModule {
                pname = "tpm-fido";
                vendorHash="sha256-qm/iDc9tnphQ4qooufpzzX7s4dbnUbR9J5L770qXw8Y=";
                version = "0.1";
                src = ./.;
            };
        }) // (rec {
        nixosModules.home-manager.tpm-fido = { config, pkgs, lib, system, ... }: {
            options.services."tpm-fido" = {
                enable = lib.mkEnableOption (lib.mdDoc "Enable tpm-fido service");
                extraPackages = lib.mkOption {
                    type = with lib.types; listOf package;
                    description = lib.mdDoc "Extra packages to be used by tpm-fido such as pinentry flavors";
                    example = "with pkgs; [ pinentry-gnome ]";
                };
            };
            config.systemd.user.services.tpm-fido = lib.mkIf (config.services."tpm-fido".enable) {
                Unit.Description = "tmp-fido service";
                Service = {
                    ExecStart = "${self.packages.${system}.default}/bin/tpm-fido";
                    Environment = "PATH=${lib.makeBinPath config.services."tpm-fido".extraPackages}";
                    Restart = "always";
                };
                Install.WantedBy = [ "default.target" ];
            };
        };
        nixosModules.home-manager.default = nixosModules.home-manager.tpm-fido;
    });
}
