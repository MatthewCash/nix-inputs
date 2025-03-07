{ stdenv, fetchurl, lib, patchelf, cdrkit, kernel, which, makeWrapper
, zlib, xorg, dbus, virtualbox}:

let
  version = virtualbox.version;
  xserverVListFunc = builtins.elemAt (lib.splitVersion xorg.xorgserver.version);

  # Forced to 1.18; vboxvideo doesn't seem to provide any newer ABI,
  # and nixpkgs doesn't support older ABIs anymore.
  xserverABI = "118";

  # Specifies how to patch binaries to make sure that libraries loaded using
  # dlopen are found. We grep binaries for specific library names and patch
  # RUNPATH in matching binaries to contain the needed library paths.
  dlopenLibs = [
    { name = "libdbus-1.so"; pkg = dbus; }
    { name = "libXfixes.so"; pkg = xorg.libXfixes; }
    { name = "libXrandr.so"; pkg = xorg.libXrandr; }
  ];

in stdenv.mkDerivation rec {
  name = "VirtualBox-GuestAdditions-${version}-${kernel.version}";

  src = fetchurl {
    url = "http://download.virtualbox.org/virtualbox/${version}/VBoxGuestAdditions_${version}.iso";
    sha256 = "b37f6aabe5a32e8b96ccca01f37fb49f4fd06674f1b29bc8fe0f423ead37b917";
  };

  KERN_DIR = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
  KERN_INCL = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/source/include";

  hardeningDisable = [ "pic" ];

  env.NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types -Wno-error=implicit-function-declaration";

  nativeBuildInputs = [ patchelf makeWrapper ];
  buildInputs = [ cdrkit ] ++ kernel.moduleBuildDependencies;


  prePatch = ''
    substituteInPlace src/vboxguest-${version}/vboxvideo/vbox_ttm.c \
      --replace "<ttm/" "<drm/ttm/"
  '';

  patchFlags = [ "-p1" "-d" "src/vboxguest-${version}" ];

  unpackPhase = ''
    isoinfo -J -i $src -x /VBoxLinuxAdditions.run > ./VBoxLinuxAdditions.run
    chmod 755 ./VBoxLinuxAdditions.run
    # An overflow leads the is-there-enough-space check to fail when there's too much space available, so fake how much space there is
    sed -i 's/\$leftspace/16383/' VBoxLinuxAdditions.run
    ./VBoxLinuxAdditions.run --noexec --keep

    # Unpack files
    cd install
    tar xfvj VBoxGuestAdditions-${if stdenv.hostPlatform.is32bit then "x86" else "amd64"}.tar.bz2
  '';

  buildPhase = ''
    # Build kernel modules.
    cd src
    find . -type f | xargs sed 's/depmod -a/true/' -i
    cd vboxguest-${version}
    # Run just make first. If we only did make install, we get symbol warnings during build.
    make
    cd ../..

    # Change the interpreter for various binaries
    for i in sbin/VBoxService bin/{VBoxClient,VBoxControl} other/mount.vboxsf; do
        patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} $i
        patchelf --set-rpath ${lib.makeLibraryPath [ stdenv.cc.cc stdenv.cc.libc zlib
          xorg.libX11 xorg.libXt xorg.libXext xorg.libXmu xorg.libXfixes xorg.libXrandr xorg.libXcursor ]} $i
    done

    for i in lib/VBoxOGL*.so
    do
        patchelf --set-rpath ${lib.makeLibraryPath [ "$out"
          xorg.libXcomposite xorg.libXdamage xorg.libXext xorg.libXfixes ]} $i
    done

    # FIXME: Virtualbox 4.3.22 moved VBoxClient-all (required by Guest Additions
    # NixOS module) to 98vboxadd-xclient. For now, just work around it:
    mv other/98vboxadd-xclient bin/VBoxClient-all

    # Remove references to /usr from various scripts and files
    sed -i -e "s|/usr/bin|$out/bin|" other/vboxclient.desktop
    sed -i -e "s|/usr/bin|$out/bin|" bin/VBoxClient-all
  '';

  installPhase = ''
    # Install kernel modules.
    cd src/vboxguest-${version}
    make install INSTALL_MOD_PATH=$out KBUILD_EXTRA_SYMBOLS=$PWD/vboxsf/Module.symvers
    cd ../..

    # Install binaries
    install -D -m 755 other/mount.vboxsf $out/bin/mount.vboxsf
    install -D -m 755 sbin/VBoxService $out/bin/VBoxService

    mkdir -p $out/bin
    install -m 755 bin/VBoxClient $out/bin
    install -m 755 bin/VBoxControl $out/bin
    install -m 755 bin/VBoxClient-all $out/bin

    wrapProgram $out/bin/VBoxClient-all \
            --prefix PATH : "${which}/bin"

    # Don't install VBoxOGL for now
    # It seems to be broken upstream too, and fixing it is far down the priority list:
    # https://www.virtualbox.org/pipermail/vbox-dev/2017-June/014561.html
    # Additionally, 3d support seems to rely on VBoxOGL.so being symlinked from
    # libGL.so (which we can't), and Oracle doesn't plan on supporting libglvnd
    # either. (#18457)
    ## Install OpenGL libraries
    #mkdir -p $out/lib
    #cp -v lib/VBoxOGL*.so $out/lib
    #mkdir -p $out/lib/dri
    #ln -s $out/lib/VBoxOGL.so $out/lib/dri/vboxvideo_dri.so

    # Install desktop file
    mkdir -p $out/etc/xdg/autostart
    cp -v other/vboxclient.desktop $out/etc/xdg/autostart

    # Install Xorg drivers
    mkdir -p $out/lib/xorg/modules/{drivers,input}
    install -m 644 other/vboxvideo_drv_${xserverABI}.so $out/lib/xorg/modules/drivers/vboxvideo_drv.so
  '';

  # Stripping breaks these binaries for some reason.
  dontStrip = true;

  # Patch RUNPATH according to dlopenLibs (see the comment there).
  postFixup = lib.concatMapStrings (library: ''
    for i in $(grep -F ${lib.escapeShellArg library.name} -l -r $out/{lib,bin}); do
      origRpath=$(patchelf --print-rpath "$i")
      patchelf --set-rpath "$origRpath:${lib.makeLibraryPath [ library.pkg ]}" "$i"
    done
  '') dlopenLibs;

  meta = {
    description = "Guest additions for VirtualBox";
    longDescription = ''
      Various add-ons which makes NixOS work better as guest OS inside VirtualBox.
      This add-on provides support for dynamic resizing of the X Display, shared
      host/guest clipboard support and guest OpenGL support.
    '';
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = "GPL";
    maintainers = [ lib.maintainers.sander ];
    platforms = [ "i686-linux" "x86_64-linux" ];
    broken = stdenv.hostPlatform.is32bit && (kernel.kernelAtLeast "5.10");
  };
}
