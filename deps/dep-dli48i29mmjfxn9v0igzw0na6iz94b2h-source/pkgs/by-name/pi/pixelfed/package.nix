{
  lib,
  fetchFromGitHub,
  php83,
  nixosTests,
  nix-update-script,
  dataDir ? "/var/lib/pixelfed",
  runtimeDir ? "/run/pixelfed",
}:

php83.buildComposerProject (finalAttrs: {
  pname = "pixelfed";
  version = "0.12.5";

  src = fetchFromGitHub {
    owner = "pixelfed";
    repo = "pixelfed";
    rev = "v${finalAttrs.version}";
    hash = "sha256-bPoYEPCWj7vAKDL/P4yjhrfp4HK9sbBh4eK0Co+xaZc=";
  };

  vendorHash = "sha256-/ep0j1KUBrpcJsd40L8PbUHSrIhV1bKRkq+qqbJB2sM=";

  postInstall = ''
    mv "$out/share/php/${finalAttrs.pname}"/* $out
    rm -R $out/bootstrap/cache
    # Move static contents for the NixOS module to pick it up, if needed.
    mv $out/bootstrap $out/bootstrap-static
    mv $out/storage $out/storage-static
    ln -s ${dataDir}/.env $out/.env
    ln -s ${dataDir}/storage $out/
    ln -s ${dataDir}/storage/app/public $out/public/storage
    ln -s ${runtimeDir} $out/bootstrap
    chmod +x $out/artisan
  '';

  passthru = {
    tests = { inherit (nixosTests.pixelfed) standard; };
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "Federated image sharing platform";
    license = licenses.agpl3Only;
    homepage = "https://pixelfed.org/";
    maintainers = [ ];
    platforms = php.meta.platforms;
  };
})
