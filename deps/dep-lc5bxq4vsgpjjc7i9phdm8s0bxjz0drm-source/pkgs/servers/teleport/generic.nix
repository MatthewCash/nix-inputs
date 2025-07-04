{
  lib,
  buildGoModule,
  rustPlatform,
  fetchFromGitHub,
  fetchYarnDeps,
  fetchpatch,
  makeWrapper,
  CoreFoundation,
  AppKit,
  binaryen,
  cargo,
  libfido2,
  nodejs,
  openssl,
  pkg-config,
  pnpm_10,
  rustc,
  Security,
  stdenv,
  xdg-utils,
  yarn,
  wasm-bindgen-cli,
  wasm-pack,
  fixup-yarn-lock,
  nixosTests,

  withRdpClient ? true,

  version,
  hash,
  vendorHash,
  extPatches ? [ ],
  cargoHash ? null,
  yarnHash ? null,
  pnpmHash ? null,
}:
assert yarnHash != null || pnpmHash != null;
let
  # This repo has a private submodule "e" which fetchgit cannot handle without failing.
  src = fetchFromGitHub {
    owner = "gravitational";
    repo = "teleport";
    rev = "v${version}";
    inherit hash;
  };
  pname = "teleport";
  inherit version;

  rdpClient = rustPlatform.buildRustPackage rec {
    pname = "teleport-rdpclient";
    useFetchCargoVendor = true;
    inherit cargoHash;
    inherit version src;

    buildAndTestSubdir = "lib/srv/desktop/rdp/rdpclient";

    buildInputs =
      [ openssl ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        CoreFoundation
        Security
      ];
    nativeBuildInputs = [ pkg-config ];

    # https://github.com/NixOS/nixpkgs/issues/161570 ,
    # buildRustPackage sets strictDeps = true;
    nativeCheckInputs = buildInputs;

    OPENSSL_NO_VENDOR = "1";

    postInstall = ''
      mkdir -p $out/include
      cp ${buildAndTestSubdir}/librdprs.h $out/include/
    '';
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = yarnHash;
  };

  webassets = stdenv.mkDerivation {
    pname = "teleport-webassets";
    inherit src version;

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = cargoHash;
    };

    pnpmDeps =
      if pnpmHash != null then
        pnpm_10.fetchDeps {
          inherit src pname version;
          hash = pnpmHash;
        }
      else
        null;

    nativeBuildInputs =
      [ nodejs ]
      ++ lib.optional (lib.versionAtLeast version "15") [
        binaryen
        cargo
        nodejs
        rustc
        rustc.llvmPackages.lld
        rustPlatform.cargoSetupHook
        wasm-bindgen-cli
        wasm-pack
      ]
      ++ (
        if lib.versionAtLeast version "16" then
          [ pnpm_10.configHook ]
        else
          [
            yarn
            fixup-yarn-lock
          ]
      );

    patches = lib.optional (lib.versionAtLeast version "16") [
      ./disable-wasm-opt-for-ironrdp.patch
    ];

    configurePhase = ''
      runHook preConfigure

      export HOME=$(mktemp -d)

      runHook postConfigure
    '';

    buildPhase = ''
      ${lib.optionalString (lib.versionOlder version "16") ''
        yarn config --offline set yarn-offline-mirror ${yarnOfflineCache}
        fixup-yarn-lock yarn.lock

        yarn install --offline \
          --frozen-lockfile \
          --ignore-engines --ignore-scripts
        patchShebangs .
      ''}

      PATH=$PATH:$PWD/node_modules/.bin

      ${
        if lib.versionAtLeast version "15" then
          ''
            pushd web/packages
            pushd shared
            # https://github.com/gravitational/teleport/blob/6b91fe5bbb9e87db4c63d19f94ed4f7d0f9eba43/web/packages/teleport/README.md?plain=1#L18-L20
            RUST_MIN_STACK=16777216 wasm-pack build ./libs/ironrdp --target web --mode no-install
            popd
            pushd teleport
            vite build
            popd
            popd
          ''
        else
          "yarn build-ui-oss"
      }
    '';

    installPhase = ''
      mkdir -p $out
      cp -R webassets/. $out
    '';
  };
in
buildGoModule rec {
  inherit pname src version;
  inherit vendorHash;
  proxyVendor = true;

  subPackages = [
    "tool/tbot"
    "tool/tctl"
    "tool/teleport"
    "tool/tsh"
  ];
  tags = [
    "libfido2"
    "webassets_embed"
  ] ++ lib.optional withRdpClient "desktop_access_rdp";

  buildInputs =
    [
      openssl
      libfido2
    ]
    ++ lib.optionals (stdenv.hostPlatform.isDarwin && withRdpClient) [
      CoreFoundation
      Security
      AppKit
    ];
  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  patches = extPatches ++ [
    ./0001-fix-add-nix-path-to-exec-env.patch
    ./rdpclient.patch
    ./tsh.patch
  ];

  # Reduce closure size for client machines
  outputs = [
    "out"
    "client"
  ];

  preBuild =
    ''
      cp -r ${webassets} webassets
    ''
    + lib.optionalString withRdpClient ''
      ln -s ${rdpClient}/lib/* lib/
      ln -s ${rdpClient}/include/* lib/srv/desktop/rdp/rdpclient/
    '';

  # Multiple tests fail in the build sandbox
  # due to trying to spawn nixbld's shell (/noshell), etc.
  doCheck = false;

  postInstall = ''
    mkdir -p $client/bin
    mv {$out,$client}/bin/tsh
    # make xdg-open overrideable at runtime
    wrapProgram $client/bin/tsh --suffix PATH : ${lib.makeBinPath [ xdg-utils ]}
    ln -s {$client,$out}/bin/tsh
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    $out/bin/tsh version | grep ${version} > /dev/null
    $client/bin/tsh version | grep ${version} > /dev/null
    $out/bin/tbot version | grep ${version} > /dev/null
    $out/bin/tctl version | grep ${version} > /dev/null
    $out/bin/teleport version | grep ${version} > /dev/null
  '';

  passthru.tests = nixosTests.teleport;

  meta = with lib; {
    description = "Certificate authority and access plane for SSH, Kubernetes, web applications, and databases";
    homepage = "https://goteleport.com/";
    license = if lib.versionAtLeast version "15" then licenses.agpl3Plus else licenses.asl20;
    maintainers = with maintainers; [
      arianvp
      justinas
      sigma
      tomberek
      freezeboy
      techknowlogick
      juliusfreudenberger
    ];
    platforms = platforms.unix;
    # go-libfido2 is broken on platforms with less than 64-bit because it defines an array
    # which occupies more than 31 bits of address space.
    # For x86_64-darwin, see See https://github.com/NixOS/nixpkgs/pull/387339#issuecomment-2745420435
    broken =
      stdenv.hostPlatform.parsed.cpu.bits < 64
      || (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isx86_64);
    knownVulnerabilities = [
      "Security fixes need a newer Go version in the toolchain, which will not be available in 24.11."
    ];
  };
}
