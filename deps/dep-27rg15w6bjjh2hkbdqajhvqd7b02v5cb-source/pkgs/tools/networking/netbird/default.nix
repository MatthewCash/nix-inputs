{ stdenv
, lib
, nixosTests
, nix-update-script
, buildGoModule
, fetchFromGitHub
, installShellFiles
, pkg-config
, gtk3
, libayatana-appindicator
, libX11
, libXcursor
, libXxf86vm
, Cocoa
, IOKit
, Kernel
, UserNotifications
, WebKit
, ui ? false
, netbird-ui
}:
let
  modules =
    if ui then {
      "client/ui" = "netbird-ui";
    } else {
      client = "netbird";
      management = "netbird-mgmt";
      signal = "netbird-signal";
    };
in
buildGoModule rec {
  pname = "netbird";
  version = "0.26.0";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-hZnxemBoMAol0m9XZPMEh/Lf0woxoLNH97bRyg8xtv4=";
  };

  vendorHash = "sha256-csa83P74Y9fHsPg5VgPfR9WMg4VKOXcIR0pOMzh0QoA=";

  nativeBuildInputs = [ installShellFiles ] ++ lib.optional ui pkg-config;

  buildInputs = lib.optionals (stdenv.isLinux && ui) [
    gtk3
    libayatana-appindicator
    libX11
    libXcursor
    libXxf86vm
  ] ++ lib.optionals (stdenv.isDarwin && ui) [
    Cocoa
    IOKit
    Kernel
    UserNotifications
    WebKit
  ];

  subPackages = lib.attrNames modules;

  ldflags = [
    "-s"
    "-w"
    "-X github.com/netbirdio/netbird/version.version=${version}"
    "-X main.builtBy=nix"
  ];

  # needs network access
  doCheck = false;

  postPatch = ''
    # make it compatible with systemd's RuntimeDirectory
    substituteInPlace client/cmd/root.go \
      --replace 'unix:///var/run/netbird.sock' 'unix:///var/run/netbird/sock'
    substituteInPlace client/ui/client_ui.go \
      --replace 'unix:///var/run/netbird.sock' 'unix:///var/run/netbird/sock'
  '';

  postInstall = lib.concatStringsSep "\n"
    (lib.mapAttrsToList
      (module: binary: ''
        mv $out/bin/${lib.last (lib.splitString "/" module)} $out/bin/${binary}
      '' + lib.optionalString (!ui) ''
        installShellCompletion --cmd ${binary} \
          --bash <($out/bin/${binary} completion bash) \
          --fish <($out/bin/${binary} completion fish) \
          --zsh <($out/bin/${binary} completion zsh)
      '')
      modules) + lib.optionalString (stdenv.isLinux && ui) ''
    mkdir -p $out/share/pixmaps
    cp $src/client/ui/netbird-systemtray-default.png $out/share/pixmaps/netbird.png

    mkdir -p $out/share/applications
    cp $src/client/ui/netbird.desktop $out/share/applications/netbird.desktop

    substituteInPlace $out/share/applications/netbird.desktop \
      --replace "Exec=/usr/bin/netbird-ui" "Exec=$out/bin/netbird-ui"
  '';

  passthru = {
    tests.netbird = nixosTests.netbird;
    tests.netbird-ui = netbird-ui;
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    homepage = "https://netbird.io";
    changelog = "https://github.com/netbirdio/netbird/releases/tag/v${version}";
    description = "Connect your devices into a single secure private WireGuard®-based mesh network with SSO/MFA and simple access controls";
    license = licenses.bsd3;
    maintainers = with maintainers; [ misuzu ];
  };
}
