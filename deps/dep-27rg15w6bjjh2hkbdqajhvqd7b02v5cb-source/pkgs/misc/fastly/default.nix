{ lib
, fetchurl
, fetchFromGitHub
, installShellFiles
, buildGoModule
, go
, makeWrapper
, viceroy
}:

buildGoModule rec {
  pname = "fastly";
  version = "10.8.3";

  src = fetchFromGitHub {
    owner = "fastly";
    repo = "cli";
    rev = "refs/tags/v${version}";
    hash = "sha256-vxtO1QR3ltDWJc6aktIXiywHDez+djeNs8IQHDMYngc=";
    # The git commit is part of the `fastly version` original output;
    # leave that output the same in nixpkgs. Use the `.git` directory
    # to retrieve the commit SHA, and remove the directory afterwards,
    # since it is not needed after that.
    leaveDotGit = true;
    postFetch = ''
      cd "$out"
      git rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  subPackages = [
    "cmd/fastly"
  ];

  vendorHash = "sha256-lTpj9fZ4SJzOdLwIVZxiZCUJxHC41BvwvDOctwckO5k=";

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  # Flags as provided by the build automation of the project:
  #   https://github.com/fastly/cli/blob/7844f9f54d56f8326962112b5534e5c40e91bf09/.goreleaser.yml#L14-L18
  ldflags = [
    "-s"
    "-w"
    "-X github.com/fastly/cli/pkg/revision.AppVersion=v${version}"
    "-X github.com/fastly/cli/pkg/revision.Environment=release"
    "-X github.com/fastly/cli/pkg/revision.GoHostOS=${go.GOHOSTOS}"
    "-X github.com/fastly/cli/pkg/revision.GoHostArch=${go.GOHOSTARCH}"
  ];
  preBuild = let
    cliConfigToml = fetchurl {
      url = "https://web.archive.org/web/20231104101556/https://developer.fastly.com/api/internal/cli-config";
      hash = "sha256-Bi5hbmMyFP4Pv2MklwNdkhGLXbI5qf6Ibvj0vWok2tI=";
    };
  in ''
    cp ${cliConfigToml} ./pkg/config/config.toml
    ldflags+=" -X github.com/fastly/cli/pkg/revision.GitCommit=$(cat COMMIT)"
  '';

  preFixup = ''
    wrapProgram $out/bin/fastly --prefix PATH : ${lib.makeBinPath [ viceroy ]} \
      --set FASTLY_VICEROY_USE_PATH 1
  '';

  postInstall = ''
    export HOME="$(mktemp -d)"
    installShellCompletion --cmd fastly \
      --bash <($out/bin/fastly --completion-script-bash) \
      --zsh <($out/bin/fastly --completion-script-zsh)
  '';

  meta = with lib; {
    description = "Command line tool for interacting with the Fastly API";
    homepage = "https://github.com/fastly/cli";
    changelog = "https://github.com/fastly/cli/blob/v${version}/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ ereslibre shyim ];
    mainProgram = "fastly";
  };
}
