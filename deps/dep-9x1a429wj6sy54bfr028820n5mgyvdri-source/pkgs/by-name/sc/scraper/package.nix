{
  lib,
  rustPlatform,
  fetchCrate,
  installShellFiles,
}:

rustPlatform.buildRustPackage rec {
  pname = "scraper";
  version = "0.23.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-s38EnVooSCL6TNjU90x2Q7lXDyOf9sWjOpxAxangyAU=";
  };

  cargoHash = "sha256-cijkLybvjwdz3k2CG0hYwSTisbJUpyI7QUG0l8xLfKQ=";

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installManPage scraper.1
  '';

  meta = {
    description = "Tool to query HTML files with CSS selectors";
    mainProgram = "scraper";
    homepage = "https://github.com/causal-agent/scraper";
    changelog = "https://github.com/causal-agent/scraper/releases/tag/v${version}";
    license = lib.licenses.isc;
    maintainers = with lib.maintainers; [ figsoda ];
  };
}
