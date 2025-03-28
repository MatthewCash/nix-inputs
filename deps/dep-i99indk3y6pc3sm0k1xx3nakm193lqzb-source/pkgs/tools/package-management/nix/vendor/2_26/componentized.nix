{
  lib,
  fetchFromGitHub,
  splicePackages,
  generateSplicesForMkScope,
  newScope,
  pkgs,
  stdenv,
  libgit2-thin-packfile,
  maintainers,
  ...
}:
let
  officialRelease = true;
  src = fetchFromGitHub (builtins.fromJSON (builtins.readFile ./source.json));

  # A new scope, so that we can use `callPackage` to inject our own interdependencies
  # without "polluting" the top level "`pkgs`" attrset.
  # This also has the benefit of providing us with a distinct set of packages
  # we can iterate over.
  nixComponents =
    lib.makeScopeWithSplicing'
      {
        inherit splicePackages;
        inherit (nixDependencies) newScope;
      }
      {
        otherSplices = generateSplicesForMkScope "nixComponents";
        f = import ./packaging/components.nix {
          inherit
            lib
            maintainers
            officialRelease
            pkgs
            src
            ;
        };
      };

  # The dependencies are in their own scope, so that they don't have to be
  # in Nixpkgs top level `pkgs` or `nixComponents`.
  nixDependencies =
    lib.makeScopeWithSplicing'
      {
        inherit splicePackages;
        inherit newScope; # layered directly on pkgs, unlike nixComponents above
      }
      {
        otherSplices = generateSplicesForMkScope "nixDependencies";
        f = import ./dependencies.nix {
          inherit pkgs;
          inherit stdenv;
          inherit libgit2-thin-packfile;
        };
      };
in
(nixComponents.overrideSource src).nix-everything
