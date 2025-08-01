{
  stdenv,
  lib,
  fetchFromGitHub,
  autoconf,
  automake,
  darwin,
  libtool,
  pkg-config,
  pkgsStatic,

  # for passthru.tests
  bind,
  cmake,
  knot-resolver,
  sbclPackages,
  luajitPackages,
  mosquitto,
  neovim,
  nodejs,
  ocamlPackages,
  python3,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  version = "1.51.0";
  pname = "libuv";

  src = fetchFromGitHub {
    owner = "libuv";
    repo = "libuv";
    rev = "v${finalAttrs.version}";
    hash = "sha256-ayTk3qkeeAjrGj5ab7wF7vpWI8XWS1EeKKUqzaD/LY0=";
  };

  outputs = [
    "out"
    "dev"
  ];

  postPatch =
    let
      toDisable = [
        "getnameinfo_basic"
        "udp_send_hang_loop" # probably network-dependent
        "tcp_connect_timeout" # tries to reach out to 8.8.8.8
        "spawn_setuid_fails"
        "spawn_setgid_fails"
        "fs_chown" # user namespaces
        "getaddrinfo_fail"
        "getaddrinfo_fail_sync"
        "tcp_connect6_link_local"
        "thread_affinity" # else "test must be run with cpu 0 affinity" when affinity is set
        "threadpool_multiple_event_loops" # times out on slow machines
        "get_passwd" # passed on NixOS but failed on other Linuxes
        "tcp_writealot"
        "udp_multicast_join"
        "udp_multicast_join6"
        "metrics_pool_events" # times out sometimes
        "fs_fstat" # https://github.com/libuv/libuv/issues/2235#issuecomment-1012086927

        # Assertion failed in test/test-tcp-bind6-error.c on line 60: r == UV_EADDRINUSE
        # Assertion failed in test/test-tcp-bind-error.c on line 99: r == UV_EADDRINUSE
        "tcp_bind6_error_addrinuse"
        "tcp_bind_error_addrinuse_listen"
        # https://github.com/libuv/libuv/pull/4075#issuecomment-1935572237
        "thread_priority"
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        # Sometimes: timeout (no output), failed uv_listen. Someone
        # should report these failures to libuv team. There tests should
        # be much more robust.
        "process_title"
        "emfile"
        "poll_duplex"
        "poll_unidirectional"
        "ipc_listen_before_write"
        "ipc_listen_after_write"
        "ipc_tcp_connection"
        "tcp_alloc_cb_fail"
        "tcp_ping_pong"
        "tcp_ref3"
        "tcp_ref4"
        "tcp_bind6_error_inval"
        "tcp_read_stop"
        "tcp_unexpected_read"
        "tcp_write_to_half_open_connection"
        "tcp_oob"
        "tcp_close_accept"
        "tcp_create_early_accept"
        "tcp_create_early"
        "tcp_close"
        "tcp_bind_error_inval"
        "tcp_bind_error_addrinuse"
        "tcp_shutdown_after_write"
        "tcp_open"
        "tcp_write_queue_order"
        "tcp_try_write"
        "multiple_listen"
        "delayed_accept"
        "udp_recv_in_a_row"
        "shutdown_close_tcp"
        "shutdown_eof"
        "shutdown_twice"
        "callback_stack"
        "tty_pty"
        "condvar_5"
        "hrtime"
        # Tests that fail when sandboxing is enabled.
        "fs_event_close_in_callback"
        "fs_event_watch_dir"
        "fs_event_error_reporting"
        "fs_event_watch_dir_recursive"
        "fs_event_watch_file"
        "fs_event_watch_file_current_dir"
        "fs_event_watch_file_exact_path"
        "process_priority"
        "udp_create_early_bad_bind"
        "fs_event_watch_delete_dir"
      ]
      ++ lib.optionals (stdenv.hostPlatform.isDarwin && lib.versionOlder finalAttrs.version "1.49.3") [
        # https://github.com/libuv/libuv/issues/4650
        # can enable on upgrade from 1.49.2
        "udp_mmsg"
      ]
      ++ lib.optionals stdenv.hostPlatform.isAarch32 [
        # I observe this test failing with some regularity on ARMv7:
        # https://github.com/libuv/libuv/issues/1871
        "shutdown_close_pipe"
      ]
      ++ lib.optionals stdenv.hostPlatform.isFreeBSD [
        # EOPNOTSUPP when performed in jailed build env
        "tcp_reuseport"
        "udp_reuseport"
        # jailed build env does not have a hostname
        "gethostname"
        # Fails when built on non-nix FreeBSD
        # https://github.com/libuv/libuv/issues/4606
        "fs_event_watch_delete_dir"
      ];
      tdRegexp = lib.concatStringsSep "\\|" toDisable;
    in
    lib.optionalString (finalAttrs.finalPackage.doCheck) ''
      sed '/${tdRegexp}/d' -i test/test-list.h
      # https://github.com/libuv/libuv/issues/4794
      substituteInPlace Makefile.am --replace-fail -lutil "-lutil -lm"
    '';

  nativeBuildInputs = [
    automake
    autoconf
    libtool
    pkg-config
  ];

  # This is part of the Darwin bootstrap, so we don’t always get
  # `libutil.dylib` automatically propagated through the SDK.
  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    (lib.getLib darwin.libutil)
  ];

  preConfigure = ''
    LIBTOOLIZE=libtoolize ./autogen.sh
  '';

  enableParallelBuilding = true;

  # separateDebugInfo breaks static build
  # https://github.com/NixOS/nixpkgs/issues/219466
  separateDebugInfo = !stdenv.hostPlatform.isStatic;

  doCheck =
    # routinely hangs on powerpc64le
    !stdenv.hostPlatform.isPower64;

  # Some of the tests use localhost networking.
  __darwinAllowLocalNetworking = true;

  passthru.tests = {
    inherit
      bind
      cmake
      knot-resolver
      mosquitto
      neovim
      nodejs
      ;
    inherit (sbclPackages) cl-libuv;
    luajit-libluv = luajitPackages.libluv;
    luajit-luv = luajitPackages.luv;
    ocaml-luv = ocamlPackages.luv;
    python-pyuv = python3.pkgs.pyuv;
    python-uvloop = python3.pkgs.uvloop;
    static = pkgsStatic.libuv;
    pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = with lib; {
    description = "Multi-platform support library with a focus on asynchronous I/O";
    homepage = "https://libuv.org/";
    changelog = "https://github.com/libuv/libuv/blob/v${finalAttrs.version}/ChangeLog";
    pkgConfigModules = [ "libuv" ];
    maintainers = [ ];
    platforms = platforms.all;
    license = with licenses; [
      mit
      isc
      bsd2
      bsd3
      cc-by-40
    ];
  };

})
