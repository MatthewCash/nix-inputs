{
  lib,
  buildGoModule,
  fetchFromGitHub,
  gitUpdater,
  testers,
  kopia,
}:

buildGoModule rec {
  pname = "kopia";
  version = "0.17.0";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Bqy9eFUvUgSdyChzh52qqPVvMi+3ad01koxVgnibbLk=";
  };

  vendorHash = "sha256-/NMp64JeCQjCcEYkE6lYzu/E+irTcwkmDCJhB04ALFY=";

  subPackages = [ "." ];

  ldflags = [
    "-X github.com/kopia/kopia/repo.BuildVersion=${version}"
    "-X github.com/kopia/kopia/repo.BuildInfo=${src.rev}"
  ];

  passthru = {
    updateScript = gitUpdater { rev-prefix = "v"; };
    tests = {
      kopia-version = testers.testVersion {
        package = kopia;
      };
    };
  };

  meta = with lib; {
    homepage = "https://kopia.io";
    description = "Cross-platform backup tool with fast, incremental backups, client-side end-to-end encryption, compression and data deduplication";
    mainProgram = "kopia";
    license = licenses.asl20;
    maintainers = [ maintainers.bbigras ];
  };
}
