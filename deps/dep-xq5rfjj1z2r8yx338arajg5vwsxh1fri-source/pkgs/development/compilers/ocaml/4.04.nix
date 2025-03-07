import ./generic.nix {
  major_version = "4";
  minor_version = "04";
  patch_version = "2";
  sha256 = "0bhgjzi78l10824qga85nlh18jg9lb6aiamf9dah1cs6jhzfsn6i";

  # If the executable is stripped it does not work
  dontStrip = true;

  patches = [
    # Compatibility with Glibc 2.34
    {
      url = "https://github.com/ocaml/ocaml/commit/6bcff7e6ce1a43e088469278eb3a9341e6a2ca5b.patch";
      sha256 = "sha256:1hd45f7mwwrrym2y4dbcwklpv0g94avbz7qrn81l7w8mrrj3bngi";
    }
    # Compatibility with Binutils 2.29
    {
      url = "https://github.com/ocaml/ocaml/commit/db11f141a0e35c7fbaec419a33c4c39d199e2635.patch";
      sha256 = "sha256-oIwmbXOCzDGyASpbQ7hd7SCs4YHjd9hBBksJ74V3GiY=";
    }
  ];

  # Workaround build failure on -fno-common toolchains like upstream
  # gcc-10. Otherwise build fails as:
  #   ld: libcamlrun.a(startup.o):(.bss+0x800): multiple definition of
  #     `caml_code_fragments_table'; libcamlrun.a(backtrace.o):(.bss+0x20): first defined here
  env.NIX_CFLAGS_COMPILE = "-fcommon";
}
