{ stdenv
, lib
, elixir
, erlang
, hex
, git
, rebar
, rebar3
, fetchMixDeps
, findutils
, makeWrapper
, coreutils
, gnused
, gnugrep
, gawk
}@inputs:

{ pname
, version
, src
, nativeBuildInputs ? [ ]
, buildInputs ? [ ]
, meta ? { }
, enableDebugInfo ? false
, mixEnv ? "prod"
, compileFlags ? [ ]

  # Mix dependencies provided as a fixed output derivation
, mixFodDeps ? null

  # Mix dependencies generated by mix2nix
  #
  # This assumes each dependency is built by buildMix or buildRebar3. Each
  # dependency needs to have a setup hook to add the lib path to $ERL_LIBS.
  # This is how Mix finds dependencies.
, mixNixDeps ? { }

, elixir ? inputs.elixir
, hex ? inputs.hex.override { inherit elixir; }

  # Remove releases/COOKIE
  #
  # People have different views on the nature of cookies. Some believe that they are
  # secrets, while others believe they are just ids for clustering nodes instead of
  # secrets.
  #
  # If you think cookie is secret, you can set this attr to true, then it will be
  # removed from nix store. If not, you can set it to false.
  #
  # For backward compatibility, it is set to true by default.
  #
  # You can always specify a custom cookie by using RELEASE_COOKIE environment
  # variable, regardless of the value of this attr.
, removeCookie ? true

  # This reduces closure size, but can lead to some hard to understand runtime
  # errors, so use with caution. See e.g.
  # https://github.com/whitfin/cachex/issues/205
  # https://framagit.org/framasoft/mobilizon/-/issues/1169
, stripDebug ? false

, ...
}@attrs:
let
  # Remove non standard attributes that cannot be coerced to strings
  overridable = builtins.removeAttrs attrs [ "compileFlags" "mixNixDeps" ];
in
assert mixNixDeps != { } -> mixFodDeps == null;
assert stripDebug -> !enableDebugInfo;

stdenv.mkDerivation (overridable // {
  nativeBuildInputs = nativeBuildInputs ++
    # Erlang/Elixir deps
    [ erlang elixir hex git ] ++
    # Mix deps
    (builtins.attrValues mixNixDeps) ++
    # other compile-time deps
    [ findutils makeWrapper ];

  buildInputs = buildInputs;

  MIX_ENV = mixEnv;
  MIX_DEBUG = if enableDebugInfo then 1 else 0;
  HEX_OFFLINE = 1;

  DEBUG = if enableDebugInfo then 1 else 0; # for Rebar3 compilation
  # The API with `mix local.rebar rebar path` makes a copy of the binary
  # some older dependencies still use rebar.
  MIX_REBAR = "${rebar}/bin/rebar";
  MIX_REBAR3 = "${rebar3}/bin/rebar3";

  LC_ALL = "C.UTF-8";

  postUnpack = ''
    # Mix and Hex
    export MIX_HOME="$TEMPDIR/mix"
    export HEX_HOME="$TEMPDIR/hex"

    # Rebar
    export REBAR_GLOBAL_CONFIG_DIR="$TEMPDIR/rebar3"
    export REBAR_CACHE_DIR="$TEMPDIR/rebar3.cache"

    ${lib.optionalString (mixFodDeps != null) ''
      # Compilation of the dependencies will require that the dependency path is
      # writable, thus a copy to the $TEMPDIR is inevitable here.
      export MIX_DEPS_PATH="$TEMPDIR/deps"
      cp --no-preserve=mode -R "${mixFodDeps}" "$MIX_DEPS_PATH"
    ''}
  '' + (attrs.postUnpack or "");

  configurePhase = attrs.configurePhase or ''
    runHook preConfigure

    ${./mix-configure-hook.sh}

    # This is needed for projects that have a specific compile step
    # the dependency needs to be compiled in order for the task
    # to be available.
    #
    # Phoenix projects for example will need compile.phoenix.
    mix deps.compile --no-deps-check --skip-umbrella-children

    # Symlink dependency sources. This is needed for projects that require
    # access to the source of their dependencies. For example, Phoenix
    # projects need javascript assets to build asset bundles.
    ${lib.optionalString (mixNixDeps != { }) ''
      mkdir -p deps

      ${lib.concatMapStringsSep "\n" (dep: ''
        dep_name=$(basename ${dep} | cut -d '-' -f2)
        dep_path="deps/$dep_name"
        if [ -d "${dep}/src" ]; then
          ln -s ${dep}/src $dep_path
        fi
      '') (builtins.attrValues mixNixDeps)}
    ''}

    # Symlink deps to build root. Similar to above, but allows for mixFodDeps
    # Phoenix projects to find javascript assets.
    ${lib.optionalString (mixFodDeps != null) ''
      ln -s ../deps ./
    ''}

    runHook postConfigure
  '';

  buildPhase = attrs.buildPhase or ''
    runHook preBuild

    mix compile --no-deps-check ${lib.concatStringsSep " " compileFlags}

    runHook postBuild
  '';

  installPhase = attrs.installPhase or ''
    runHook preInstall

    mix release --no-deps-check --path "$out"

    runHook postInstall
  '';

  postFixup = ''
    # Remove files for Microsoft Windows
    rm -f "$out"/bin/*.bat

    # Wrap programs in $out/bin with their runtime deps
    for f in $(find $out/bin/ -type f -executable); do
      wrapProgram "$f" \
        --prefix PATH : ${lib.makeBinPath [
          coreutils
          gnused
          gnugrep
          gawk
        ]}
    done
  '' + lib.optionalString removeCookie ''
    if [ -e $out/releases/COOKIE ]; then
      rm $out/releases/COOKIE
    fi
  '' + lib.optionalString stripDebug ''
    # Strip debug symbols to avoid hardreferences to "foreign" closures actually
    # not needed at runtime, while at the same time reduce size of BEAM files.
    erl -noinput -eval 'lists:foreach(fun(F) -> io:format("Stripping ~p.~n", [F]), beam_lib:strip(F) end, filelib:wildcard("'"$out"'/**/*.beam"))' -s init stop
  '';

  # TODO: remove erlang references in resulting derivation
  #
  # # Step 1 - investigate why the resulting derivation still has references to erlang.
  #
  # The reason is that the generated binaries contains erlang reference. Here's a repo to
  # demonstrate the problem - <https://github.com/plastic-gun/nix-mix-release-unwanted-references>.
  #
  #
  # # Step 2 - remove erlang references from the binaries
  #
  # As said in above repo, it's hard to remove erlang references from `.beam` binaries.
  #
  # We need more experienced developers to resolve this issue.
  #
  #
  # # Tips
  #
  # When resolving this issue, it is convenient to fail the build when erlang is referenced,
  # which can be achieved by using:
  #
  #   disallowedReferences = [ erlang ];
  #
})