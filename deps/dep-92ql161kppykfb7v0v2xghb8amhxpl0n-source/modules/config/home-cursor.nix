{ config, options, lib, pkgs, ... }:

let
  inherit (lib) mkDefault mkEnableOption mkOption types;

  cfg = config.home.pointerCursor;

  pointerCursorModule = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        example = lib.literalExpression "pkgs.vanilla-dmz";
        description = "Package providing the cursor theme.";
      };

      name = mkOption {
        type = types.str;
        example = "Vanilla-DMZ";
        description = "The cursor name within the package.";
      };

      size = mkOption {
        type = types.int;
        default = 32;
        example = 64;
        description = "The cursor size.";
      };

      x11 = {
        enable = mkEnableOption ''
          x11 config generation for {option}`home.pointerCursor`
        '';

        defaultCursor = mkOption {
          type = types.str;
          default = "left_ptr";
          example = "X_cursor";
          description = "The default cursor file to use within the package.";
        };
      };

      gtk = {
        enable = mkEnableOption ''
          gtk config generation for {option}`home.pointerCursor`
        '';
      };

      hyprcursor = {
        enable = mkEnableOption "hyprcursor config generation";

        size = mkOption {
          type = types.nullOr types.int;
          example = 32;
          default = null;
          description = "The cursor size for hyprcursor.";
        };
      };

      sway = {
        enable = mkEnableOption
          "sway config generation for {option}`home.pointerCursor`";
      };
    };
  };

  cursorPath =
    "${cfg.package}/share/icons/${lib.escapeShellArg cfg.name}/cursors/${
      lib.escapeShellArg cfg.x11.defaultCursor
    }";

  defaultIndexThemePackage = pkgs.writeTextFile {
    name = "index.theme";
    destination = "/share/icons/default/index.theme";
    # Set name in icons theme, for compatibility with AwesomeWM etc. See:
    # https://github.com/nix-community/home-manager/issues/2081
    # https://wiki.archlinux.org/title/Cursor_themes#XDG_specification
    text = ''
      [Icon Theme]
      Name=Default
      Comment=Default Cursor Theme
      Inherits=${cfg.name}
    '';
  };

in {
  meta.maintainers = [ lib.maintainers.league ];

  imports = [
    (lib.mkAliasOptionModule [ "xsession" "pointerCursor" "package" ] [
      "home"
      "pointerCursor"
      "package"
    ])
    (lib.mkAliasOptionModule [ "xsession" "pointerCursor" "name" ] [
      "home"
      "pointerCursor"
      "name"
    ])
    (lib.mkAliasOptionModule [ "xsession" "pointerCursor" "size" ] [
      "home"
      "pointerCursor"
      "size"
    ])
    (lib.mkAliasOptionModule [ "xsession" "pointerCursor" "defaultCursor" ] [
      "home"
      "pointerCursor"
      "x11"
      "defaultCursor"
    ])

    ({ ... }: {
      warnings = lib.optional (lib.any (x:
        lib.getAttrFromPath
        ([ "xsession" "pointerCursor" ] ++ [ x ] ++ [ "isDefined" ])
        options) [ "package" "name" "size" "defaultCursor" ]) ''
          The option `xsession.pointerCursor` has been merged into `home.pointerCursor` and will be removed
          in the future. Please change to set `home.pointerCursor` directly and enable `home.pointerCursor.x11.enable`
          to generate x11 specific cursor configurations. You can refer to the documentation for more details.
        '';
    })
  ];

  options = {
    home.pointerCursor = mkOption {
      type = types.nullOr pointerCursorModule;
      default = null;
      description = ''
        Cursor configuration. Set to `null` to disable.

        Top-level options declared under this submodule are backend independent
        options. Options declared under namespaces such as `x11`
        are backend specific options. By default, only backend independent cursor
        configurations are generated. If you need configurations for specific
        backends, you can toggle them via the enable option. For example,
        [](#opt-home.pointerCursor.x11.enable)
        will enable x11 cursor configurations.

        Note that this will merely generate the cursor configurations.
        To apply the configurations, the relevant subsytems must also be configured.
        For example, [](#opt-home.pointerCursor.gtk.enable) will generate
        the gtk cursor configuration, but [](#opt-gtk.enable) needs
        to be set for it to be applied.
      '';
    };
  };

  config = lib.mkIf (cfg != null) (lib.mkMerge [
    {
      assertions = [
        (lib.hm.assertions.assertPlatform "home.pointerCursor" pkgs
          lib.platforms.linux)
      ];

      home.packages = [ cfg.package defaultIndexThemePackage ];

      home.sessionVariables = {
        XCURSOR_SIZE = mkDefault cfg.size;
        XCURSOR_THEME = mkDefault cfg.name;
      };

      # Set directory to look for cursors in, needed for some applications
      # that are unable to find cursors otherwise. See:
      # https://github.com/nix-community/home-manager/issues/2812
      # https://wiki.archlinux.org/title/Cursor_themes#Environment_variable
      home.sessionSearchVariables.XCURSOR_PATH =
        [ "${config.home.profileDirectory}/share/icons" ];

      # Add symlink of cursor icon directory to $HOME/.icons, needed for
      # backwards compatibility with some applications. See:
      # https://specifications.freedesktop.org/icon-theme-spec/latest/ar01s03.html
      home.file.".icons/default/index.theme".source =
        "${defaultIndexThemePackage}/share/icons/default/index.theme";
      home.file.".icons/${cfg.name}".source =
        "${cfg.package}/share/icons/${cfg.name}";

      # Add cursor icon link to $XDG_DATA_HOME/icons as well for redundancy.
      xdg.dataFile."icons/default/index.theme".source =
        "${defaultIndexThemePackage}/share/icons/default/index.theme";
      xdg.dataFile."icons/${cfg.name}".source =
        "${cfg.package}/share/icons/${cfg.name}";
    }

    (lib.mkIf cfg.x11.enable {
      xsession.profileExtra = ''
        ${pkgs.xorg.xsetroot}/bin/xsetroot -xcf ${cursorPath} ${
          toString cfg.size
        }
      '';

      xresources.properties = {
        "Xcursor.theme" = cfg.name;
        "Xcursor.size" = cfg.size;
      };
    })

    (lib.mkIf cfg.gtk.enable {
      gtk.cursorTheme = mkDefault { inherit (cfg) package name size; };
    })

    (lib.mkIf cfg.hyprcursor.enable {
      home.sessionVariables = {
        HYPRCURSOR_THEME = cfg.name;
        HYPRCURSOR_SIZE =
          if cfg.hyprcursor.size != null then cfg.hyprcursor.size else cfg.size;
      };
    })

    (lib.mkIf cfg.sway.enable {
      wayland.windowManager.sway = {
        config = {
          seat = {
            "*" = {
              xcursor_theme =
                "${cfg.name} ${toString config.gtk.cursorTheme.size}";
            };
          };
        };
      };
    })
  ]);
}
