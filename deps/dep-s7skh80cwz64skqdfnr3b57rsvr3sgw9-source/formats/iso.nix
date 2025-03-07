{
  modulesPath,
  ...
}: {
  imports = [
    "${toString modulesPath}/installer/cd-dvd/iso-image.nix"
  ];

  # EFI booting
  isoImage.makeEfiBootable = true;

  # USB booting
  isoImage.makeUsbBootable = true;

  formatAttr = "isoImage";
  fileExtension = ".iso";
}
