{ mkDerivation }:

mkDerivation {
  version = "24.3.4.17";
  sha256 = "sha256-V26pZEyFo+c+ztDDkjDNFK6LTw5xzF8gQYepWGNlGKg=";
  meta.knownVulnerabilities = [
    ''
      Erlang OTP 24 is end of life and no longer maintained.
    ''
  ];
}
