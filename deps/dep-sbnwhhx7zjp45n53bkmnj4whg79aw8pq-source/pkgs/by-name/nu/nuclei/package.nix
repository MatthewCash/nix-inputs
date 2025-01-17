{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "nuclei";
  version = "3.3.5";

  src = fetchFromGitHub {
    owner = "projectdiscovery";
    repo = "nuclei";
    tag = "v${version}";
    hash = "sha256-L8HOuPENnyM56ac1dqJRCYzqN9wRnGt4RoF8BZji0Z0=";
  };

  vendorHash = "sha256-ZGFzZ/WpiVChtvMJQH3lR4k2it1KF0QwrMQchQz5XYw=";
  proxyVendor = true; # hash mismatch between Linux and Darwin

  subPackages = [ "cmd/nuclei/" ];

  ldflags = [
    "-w"
    "-s"
  ];

  # Test files are not part of the release tarball
  doCheck = false;

  meta = with lib; {
    description = "Tool for configurable targeted scanning";
    longDescription = ''
      Nuclei is used to send requests across targets based on a template
      leading to zero false positives and providing effective scanning
      for known paths. Main use cases for nuclei are during initial
      reconnaissance phase to quickly check for low hanging fruits or
      CVEs across targets that are known and easily detectable.
    '';
    homepage = "https://github.com/projectdiscovery/nuclei";
    changelog = "https://github.com/projectdiscovery/nuclei/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [
      fab
      Misaka13514
    ];
    mainProgram = "nuclei";
  };
}
