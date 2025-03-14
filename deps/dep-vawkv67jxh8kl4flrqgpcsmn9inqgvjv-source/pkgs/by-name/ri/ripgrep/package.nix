{
  lib,
  stdenv,
  buildPackages,
  fetchFromGitHub,
  rustPlatform,
  installShellFiles,
  pkg-config,
  apple-sdk_11,
  withPCRE2 ? true,
  pcre2,
}:

let
  canRunRg = stdenv.hostPlatform.emulatorAvailable buildPackages;
  rg = "${stdenv.hostPlatform.emulator buildPackages} $out/bin/rg";
in
rustPlatform.buildRustPackage rec {
  pname = "ripgrep";
  version = "14.1.1";

  src = fetchFromGitHub {
    owner = "BurntSushi";
    repo = pname;
    rev = version;
    hash = "sha256-gyWnahj1A+iXUQlQ1O1H1u7K5euYQOld9qWm99Vjaeg=";
  };

  cargoHash = "sha256-b+iA8iTYWlczBpNq9eyHrWG8LMU4WPBzaU6pQRht+yE=";

  nativeBuildInputs = [ installShellFiles ] ++ lib.optional withPCRE2 pkg-config;
  buildInputs =
    lib.optional withPCRE2 pcre2
    ++ lib.optional stdenv.hostPlatform.isDarwin apple-sdk_11;

  buildFeatures = lib.optional withPCRE2 "pcre2";

  preFixup = lib.optionalString canRunRg ''
    ${rg} --generate man > rg.1
    installManPage rg.1

    installShellCompletion --cmd rg \
      --bash <(${rg} --generate complete-bash) \
      --fish <(${rg} --generate complete-fish) \
      --zsh <(${rg} --generate complete-zsh)
  '';

  doInstallCheck = true;
  installCheckPhase =
    ''
      file="$(mktemp)"
      echo "abc\nbcd\ncde" > "$file"
      ${rg} -N 'bcd' "$file"
      ${rg} -N 'cd' "$file"
    ''
    + lib.optionalString withPCRE2 ''
      echo '(a(aa)aa)' | ${rg} -P '\((a*|(?R))*\)'
    '';

  meta = with lib; {
    description = "Utility that combines the usability of The Silver Searcher with the raw speed of grep";
    homepage = "https://github.com/BurntSushi/ripgrep";
    changelog = "https://github.com/BurntSushi/ripgrep/releases/tag/${version}";
    license = with licenses; [
      unlicense # or
      mit
    ];
    maintainers = with maintainers; [
      globin
      ma27
      zowoq
    ];
    mainProgram = "rg";
  };
}
