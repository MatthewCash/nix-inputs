{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption optionalString types;

  cfg = config.programs.zsh.zplug;

  pluginModule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "The name of the plugin.";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "The plugin tags.";
      };
    };
  };
in
{
  options.programs.zsh.zplug = {
    enable = lib.mkEnableOption "zplug - a zsh plugin manager";

    package = lib.mkPackageOption pkgs "zplug" { };

    plugins = mkOption {
      default = [ ];
      type = types.listOf pluginModule;
      description = "List of zplug plugins.";
    };

    zplugHome = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.zplug";
      defaultText = "~/.zplug";
      apply = toString;
      description = "Path to zplug home directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.zsh.initContent = lib.mkOrder 550 ''
      export ZPLUG_HOME=${cfg.zplugHome}

      source ${cfg.package}/share/zplug/init.zsh

      ${optionalString (cfg.plugins != [ ]) ''
        ${lib.concatStrings (
          map (plugin: ''
            zplug "${plugin.name}"${
              optionalString (plugin.tags != [ ]) ''
                ${lib.concatStrings (map (tag: ", ${tag}") plugin.tags)}
              ''
            }
          '') cfg.plugins
        )}
      ''}

      if ! zplug check; then
        zplug install
      fi

      zplug load
    '';

  };
}
