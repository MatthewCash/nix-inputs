{ lib, callPackage, ... }@args:

let
  k3s_builder = import ./builder.nix lib;
  common = opts: callPackage (k3s_builder opts);
  # extraArgs is the extra arguments passed in by the caller to propogate downward.
  # This is to allow all-packages.nix to do:
  #
  #     let k3s_1_23 = (callPackage ./path/to/k3s {
  #       commonK3sArg = ....
  #     }).k3s_1_23;
  extraArgs = builtins.removeAttrs args [ "callPackage" ];
in
{
  # 1_28 can be built with the same builder as 1_30
  k3s_1_28 =
    (common (
      (import ./1_28/versions.nix)
      // {
        updateScript = [
          ./update-script.sh
          "28"
        ];
      }
    ) extraArgs).overrideAttrs
      {
        meta.knownVulnerabilities = [
          "k3s_1_28 has reached end-of-life on 2024-10-28. See https://www.suse.com/lifecycle#k3s"
        ];
      };

  # 1_29 can be built with the same builder as 1_30
  k3s_1_29 =
    (common (
      (import ./1_29/versions.nix)
      // {
        updateScript = [
          ./update-script.sh
          "29"
        ];
      }
    ) extraArgs).overrideAttrs
      {
        meta.knownVulnerabilities = [
          "k3s_1_29 has reached end-of-life on 2025-02-28. See https://www.suse.com/lifecycle#k3s"
        ];
      };

  k3s_1_30 = common (
    (import ./1_30/versions.nix)
    // {
      updateScript = [
        ./update-script.sh
        "30"
      ];
    }
  ) extraArgs;

  k3s_1_31 = common (
    (import ./1_31/versions.nix)
    // {
      updateScript = [
        ./update-script.sh
        "31"
      ];
    }
  ) extraArgs;
}
