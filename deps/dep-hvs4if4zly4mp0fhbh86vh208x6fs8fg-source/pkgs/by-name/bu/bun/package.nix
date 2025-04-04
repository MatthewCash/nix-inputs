{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  unzip,
  installShellFiles,
  openssl,
  writeShellScript,
  curl,
  jq,
  common-updater-scripts,
}:

stdenvNoCC.mkDerivation rec {
  version = "1.1.31";
  pname = "bun";

  src =
    passthru.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  strictDeps = true;
  nativeBuildInputs = [
    unzip
    installShellFiles
  ] ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = [ openssl ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm 755 ./bun $out/bin/bun
    ln -s $out/bin/bun $out/bin/bunx

    runHook postInstall
  '';

  postPhases = lib.optionals (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) [
    "postPatchelf"
  ];
  postPatchelf = ''
    completions_dir=$(mktemp -d)

    SHELL="bash" $out/bin/bun completions $completions_dir
    SHELL="zsh" $out/bin/bun completions $completions_dir
    SHELL="fish" $out/bin/bun completions $completions_dir

    installShellCompletion --name bun \
      --bash $completions_dir/bun.completion.bash \
      --zsh $completions_dir/_bun \
      --fish $completions_dir/bun.fish
  '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-darwin-aarch64.zip";
        hash = "sha256-dOQFfkxCiOFmAr11CjSdSKNpiLERkbVWawAuy8ASkJE=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-aarch64.zip";
        hash = "sha256-ZuU14GvAtf1n1sA8amtZUSGp5iJ5qp/SI2wrw4Gwe/4=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-darwin-x64-baseline.zip";
        hash = "sha256-qN8ciVHzHH8GgR89GDgfvteMV+YawMUQLiXNwYyN+wU=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
        hash = "sha256-zHitG4Ktt+iCKk9GrC3C4MRSWhUxh89kW9bUeHzqNJs=";
      };
    };
    updateScript = writeShellScript "update-bun" ''
      set -o errexit
      export PATH="${
        lib.makeBinPath [
          curl
          jq
          common-updater-scripts
        ]
      }"
      NEW_VERSION=$(curl --silent https://api.github.com/repos/oven-sh/bun/releases/latest | jq '.tag_name | ltrimstr("bun-v")' --raw-output)
      if [[ "${version}" = "$NEW_VERSION" ]]; then
          echo "The new version same as the old version."
          exit 0
      fi
      for platform in ${lib.escapeShellArgs meta.platforms}; do
        update-source-version "bun" "$NEW_VERSION" --ignore-same-version --source-key="sources.$platform"
      done
    '';
  };
  meta = with lib; {
    homepage = "https://bun.sh";
    changelog = "https://bun.sh/blog/bun-v${version}";
    description = "Incredibly fast JavaScript runtime, bundler, transpiler and package manager – all in one";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    longDescription = ''
      All in one fast & easy-to-use tool. Instead of 1,000 node_modules for development, you only need bun.
    '';
    license = with licenses; [
      mit # bun core
      lgpl21Only # javascriptcore and webkit
    ];
    mainProgram = "bun";
    maintainers = with maintainers; [
      DAlperin
      jk
      thilobillerbeck
      cdmistman
      coffeeispower
      diogomdp
    ];
    platforms = builtins.attrNames passthru.sources;
    # Broken for Musl at 2024-01-13, tracking issue:
    # https://github.com/NixOS/nixpkgs/issues/280716
    broken = stdenvNoCC.hostPlatform.isMusl;

    # Hangs when run via Rosetta 2 on Apple Silicon
    hydraPlatforms = lib.lists.remove "x86_64-darwin" lib.platforms.all;
  };
}
