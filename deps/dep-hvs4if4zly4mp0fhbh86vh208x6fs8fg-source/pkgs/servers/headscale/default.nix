{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  nixosTests,
}:
buildGoModule rec {
  pname = "headscale";
  version = "0.23.0";

  src = fetchFromGitHub {
    owner = "juanfont";
    repo = "headscale";
    rev = "v${version}";
    hash = "sha256-5tlnVNpn+hJayxHjTpbOO3kRInOYOFz0pe9pwjXZlBE=";
  };

  # Merged post-v0.23.0, so should be removed with next release.
  patches = [ ./patches/config-loosen-up-BaseDomain-and-ServerURL-checks.patch ];

  vendorHash = "sha256-+8dOxPG/Q+wuHgRwwWqdphHOuop0W9dVyClyQuh7aRc=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/juanfont/headscale/cmd/headscale/cli.Version=v${version}"
  ];

  nativeBuildInputs = [ installShellFiles ];
  checkFlags = [ "-short" ];

  postInstall = ''
    installShellCompletion --cmd headscale \
      --bash <($out/bin/headscale completion bash) \
      --fish <($out/bin/headscale completion fish) \
      --zsh <($out/bin/headscale completion zsh)
  '';

  passthru.tests = { inherit (nixosTests) headscale; };

  meta = with lib; {
    homepage = "https://github.com/juanfont/headscale";
    description = "Open source, self-hosted implementation of the Tailscale control server";
    longDescription = ''
      Tailscale is a modern VPN built on top of Wireguard. It works like an
      overlay network between the computers of your networks - using all kinds
      of NAT traversal sorcery.

      Everything in Tailscale is Open Source, except the GUI clients for
      proprietary OS (Windows and macOS/iOS), and the
      'coordination/control server'.

      The control server works as an exchange point of Wireguard public keys for
      the nodes in the Tailscale network. It also assigns the IP addresses of
      the clients, creates the boundaries between each user, enables sharing
      machines between users, and exposes the advertised routes of your nodes.

      Headscale implements this coordination server.
    '';
    license = licenses.bsd3;
    mainProgram = "headscale";
    maintainers = with maintainers; [
      nkje
      jk
      kradalby
      misterio77
      ghuntley
    ];
  };
}
