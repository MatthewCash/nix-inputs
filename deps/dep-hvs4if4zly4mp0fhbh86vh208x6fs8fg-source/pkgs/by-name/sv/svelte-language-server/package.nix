{
  lib,
  buildNpmPackage,
  fetchurl,
}:
let
  version = "0.17.0";
in
buildNpmPackage {
  pname = "svelte-language-server";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/svelte-language-server/-/svelte-language-server-${version}.tgz";
    hash = "sha256-3JcpdpvxkOAIMAMsZx5UF1Sp+O6zC3jwYJGRdoZNbQg=";
  };

  npmDepsHash = "sha256-poUbH9U/zN9LiuCCI1FCz+MnoYt8De64pMLSbtmoN30=";

  postPatch = ''
    ln -s ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Language server (implementing the language server protocol) for Svelte";
    downloadPage = "https://www.npmjs.com/package/svelte-language-server";
    homepage = "https://github.com/sveltejs/language-tools";
    license = lib.licenses.mit;
    mainProgram = "svelteserver";
    maintainers = [ ];
  };
}
