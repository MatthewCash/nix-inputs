{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  testers,
  nixosTests,
  opentelemetry-collector,
}:

buildGoModule rec {
  pname = "opentelemetry-collector";
  version = "0.109.0";

  src = fetchFromGitHub {
    owner = "open-telemetry";
    repo = "opentelemetry-collector";
    rev = "v${version}";
    hash = "sha256-ShVUBohSnIoeq2aTWJ9IMXKt0CeRv3CZjlqpYHR9DhY=";
  };
  # there is a nested go.mod
  sourceRoot = "${src.name}/cmd/otelcorecol";
  vendorHash = "sha256-rXC4lm2ZvO3k6h1ZiYB+FskhW0c2uJyPLZg6n125MZE=";

  nativeBuildInputs = [ installShellFiles ];

  # upstream strongly recommends disabling CGO
  # additionally dependencies have had issues when GCO was enabled that weren't caught upstream
  # https://github.com/open-telemetry/opentelemetry-collector/blob/main/CONTRIBUTING.md#using-cgo
  CGO_ENABLED = 0;

  preBuild = ''
    # set the build version, can't be done via ldflags
    sed -i -E 's/Version:(\s*)".*"/Version:\1"${version}"/' main.go
  '';

  ldflags = [
    "-s"
    "-w"
  ];

  postInstall = ''
    installShellCompletion --cmd otelcorecol \
      --bash <($out/bin/otelcorecol completion bash) \
      --fish <($out/bin/otelcorecol completion fish) \
      --zsh <($out/bin/otelcorecol completion zsh)
  '';

  passthru.tests = {
    version = testers.testVersion {
      inherit version;
      package = opentelemetry-collector;
      command = "otelcorecol -v";
    };
    inherit (nixosTests) opentelemetry-collector;
  };

  meta = with lib; {
    homepage = "https://github.com/open-telemetry/opentelemetry-collector";
    changelog = "https://github.com/open-telemetry/opentelemetry-collector/blob/v${version}/CHANGELOG.md";
    description = "Vendor-agnostic implementation on how to receive, process and export telemetry data";
    longDescription = ''
      The OpenTelemetry Collector offers a vendor-agnostic implementation on how
      to receive, process and export telemetry data. In addition, it removes the
      need to run, operate and maintain multiple agents/collectors in order to
      support open-source telemetry data formats (e.g. Jaeger, Prometheus, etc.)
      sending to multiple open-source or commercial back-ends.
    '';
    license = licenses.asl20;
    maintainers = with maintainers; [
      uri-canva
      jk
    ];
    mainProgram = "otelcorecol";
  };
}
