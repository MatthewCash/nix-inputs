{
  buildGoModule,
  fetchFromGitHub,
  lib,
  testers,
  grpc-gateway,
}:

buildGoModule rec {
  pname = "grpc-gateway";
  version = "2.22.0";

  src = fetchFromGitHub {
    owner = "grpc-ecosystem";
    repo = "grpc-gateway";
    rev = "v${version}";
    sha256 = "sha256-I1w3gfV06J8xG1xJ+XuMIGkV2/Ofszo7SCC+z4Xb6l4=";
  };

  vendorHash = "sha256-S4hcD5/BSGxM2qdJHMxOkxsJ5+Ks6m4lKHSS9+yZ17c=";

  ldflags = [
    "-X=main.version=${version}"
    "-X=main.date=1970-01-01T00:00:00Z"
    "-X=main.commit=unknown"
  ];

  passthru.tests = {
    version = testers.testVersion {
      package = grpc-gateway;
      command = "protoc-gen-grpc-gateway --version";
      version = "Version ${version}, commit unknown, built at 1970-01-01T00:00:00Z";
    };
    openapiv2Version = testers.testVersion {
      package = grpc-gateway;
      command = "protoc-gen-openapiv2 --version";
      version = "Version ${version}, commit unknown, built at 1970-01-01T00:00:00Z";
    };
  };

  meta = with lib; {
    description = "A gRPC to JSON proxy generator plugin for Google Protocol Buffers";
    longDescription = ''
      This is a plugin for the Google Protocol Buffers compiler (protoc). It reads
      protobuf service definitions and generates a reverse-proxy server which
      translates a RESTful HTTP API into gRPC. This server is generated according to
      the google.api.http annotations in the protobuf service definitions.
    '';
    homepage = "https://github.com/grpc-ecosystem/grpc-gateway";
    license = licenses.bsd3;
    maintainers = with maintainers; [ happyalu ];
  };
}
