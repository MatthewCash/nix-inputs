{
  lib,
  newScope,
  dbus,
  IOKit,
  CoreFoundation,
  Foundation,
  Security,
}:

lib.makeScope newScope (
  self: with self; {
    gstat = callPackage ./gstat.nix { inherit Security; };
    formats = callPackage ./formats.nix { inherit IOKit Foundation; };
    polars = callPackage ./polars.nix { inherit IOKit Foundation; };
    query = callPackage ./query.nix { inherit IOKit CoreFoundation; };
    regex = throw "`nu_plugin_regex` is no longer compatible with the current Nushell release.";
    net = callPackage ./net.nix { inherit IOKit CoreFoundation; };
    units = callPackage ./units.nix { inherit IOKit Foundation; };
    highlight = callPackage ./highlight.nix { inherit IOKit Foundation; };
    dbus = callPackage ./dbus.nix {
      inherit dbus;
      nushell_plugin_dbus = self.dbus;
    };
    skim = callPackage ./skim.nix { inherit IOKit CoreFoundation; };
  }
)
