{
  lib,
  stdenv,
  fetchFromGitHub,
  installShellFiles,
  rustPlatform,
  Security,
}:

rustPlatform.buildRustPackage rec {
  pname = "jwt-cli";
  version = "6.1.1";

  src = fetchFromGitHub {
    owner = "mike-engel";
    repo = pname;
    rev = version;
    sha256 = "sha256-v6wy3+j351TZUasj7WvJwCDoqXRIcJutmNZLvwGcwBE=";
  };

  cargoHash = "sha256-o9W1yMsTwByAiKiiY4Dx+RxOpvNuGlW7pqFB1pxVYZo=";

  nativeBuildInputs = [ installShellFiles ];

  buildInputs = lib.optional stdenv.hostPlatform.isDarwin Security;

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd jwt \
      --bash <($out/bin/jwt completion bash) \
      --fish <($out/bin/jwt completion fish) \
      --zsh <($out/bin/jwt completion zsh)
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/jwt --version > /dev/null
    $out/bin/jwt decode eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c \
      | grep -q 'John Doe'
  '';

  meta = with lib; {
    description = "Super fast CLI tool to decode and encode JWTs";
    homepage = "https://github.com/mike-engel/jwt-cli";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ rycee ];
    mainProgram = "jwt";
  };
}
