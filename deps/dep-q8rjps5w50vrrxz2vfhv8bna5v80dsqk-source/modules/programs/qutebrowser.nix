{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    literalExpression
    mapAttrsToList
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.qutebrowser;

  pythonize =
    v:
    if v == null then
      "None"
    else if builtins.isBool v then
      (if v then "True" else "False")
    else if builtins.isString v then
      ''"${v}"''
    else if builtins.isList v then
      "[${concatStringsSep ", " (map pythonize v)}]"
    else
      builtins.toString v;

  formatDictLine =
    o: n: v:
    ''${o}['${n}'] = "${v}"'';

  formatKeyBindings =
    m: b:
    let
      formatKeyBinding =
        m: k: c:
        if c == null then
          ''config.unbind("${k}", mode="${m}")''
        else
          ''config.bind("${k}", "${lib.escape [ ''"'' ] c}", mode="${m}")'';
    in
    concatStringsSep "\n" (mapAttrsToList (formatKeyBinding m) b);

  formatQuickmarks = n: s: "${n} ${s}";

  # flattenSettings attrset -> [ [ <opt_path> <opt_value>] ]
  flattenSettings =
    x:
    lib.collect (x: !builtins.isAttrs x) (
      lib.mapAttrsRecursive (path: value: [
        (lib.concatStringsSep "." path)
        value
      ]) x
    );

  configSet = l: "config.set(${lib.concatStringsSep ", " (map pythonize l)})";

  setUrlConfig = url: conf: map (x: configSet (x ++ [ url ])) (flattenSettings conf);
in
{
  options.programs.qutebrowser = {
    enable = lib.mkEnableOption "qutebrowser";

    package = lib.mkPackageOption pkgs "qutebrowser" { nullable = true; };

    aliases = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Aliases for commands.
      '';
    };

    loadAutoconfig = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Load settings configured via the GUI.
      '';
    };

    searchEngines = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Search engines that can be used via the address bar. Maps a search
        engine name (such as `DEFAULT`, or
        `ddg`) to a URL with a `{}`
        placeholder. The placeholder will be replaced by the search term, use
        `{{` and `}}` for literal
        `{/}` signs. The search engine named
        `DEFAULT` is used when
        `url.auto_search` is turned on and something else than
        a URL was entered to be opened. Other search engines can be used by
        prepending the search engine name to the search term, for example
        `:open google qutebrowser`.
      '';
      example = literalExpression ''
        {
          w = "https://en.wikipedia.org/wiki/Special:Search?search={}&go=Go&ns0=1";
          aw = "https://wiki.archlinux.org/?search={}";
          nw = "https://wiki.nixos.org/index.php?search={}";
          g = "https://www.google.com/search?hl=en&q={}";
        }
      '';
    };

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = ''
        Options to add to qutebrowser {file}`config.py` file.
        See <https://qutebrowser.org/doc/help/settings.html>
        for options.
      '';
      example = literalExpression ''
        {
          colors = {
            hints = {
              bg = "#000000";
              fg = "#ffffff";
            };
            tabs.bar.bg = "#000000";
          };
          tabs.tabs_are_windows = true;
        }
      '';
    };

    keyMappings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        This setting can be used to map keys to other keys. When the key used
        as dictionary-key is pressed, the binding for the key used as
        dictionary-value is invoked instead. This is useful for global
        remappings of keys, for example to map Ctrl-[ to Escape. Note that when
        a key is bound (via `bindings.default` or
        `bindings.commands`), the mapping is ignored.
      '';
    };

    enableDefaultBindings = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Disable to prevent loading default key bindings.
      '';
    };

    keyBindings = mkOption {
      type = with types; attrsOf (attrsOf (nullOr (separatedString " ;; ")));
      default = { };
      description = ''
        Key bindings mapping keys to commands in different modes. This setting
        is a dictionary containing mode names and dictionaries mapping keys to
        commands: `{mode: {key: command}}` If you want to map
        a key to another key, check the `keyMappings` setting
        instead. For modifiers, you can use either `-` or
        `+` as delimiters, and these names:

        Control
        : `Control`, `Ctrl`

        Meta
        : `Meta`, `Windows`, `Mod4`

        Alt
        : `Alt`, `Mod1`

        Shift
        : `Shift`

        For simple keys (no `<>`-signs), a capital
        letter means the key is pressed with Shift. For special keys (with
        `<>`-signs), you need to explicitly add
        `Shift-` to match a key pressed with shift. If you
        want a binding to do nothing, bind it to the `nop`
        command. If you want a default binding to be passed through to the
        website, bind it to null. Note that some commands which are only useful
        for bindings (but not used interactively) are hidden from the command
        completion. See `:help` for a full list of available
        commands. The following modes are available:

        `normal`
        : Default mode, where most commands are invoked.

        `insert`
        : Entered when an input field is focused on a website, or by
          pressing `i` in normal mode. Passes through almost all keypresses
          to the website, but has some bindings like
          `<Ctrl-e>` to open an external editor.
          Note that single keys can't be bound in this mode.

        `hint`
        : Entered when `f` is pressed to select links with the keyboard. Note
          that single keys can't be bound in this mode.

        `passthrough`
        : Similar to insert mode, but passes through all keypresses except
          `<Escape>` to leave the mode. It might be
          useful to bind `<Escape>` to some other
          key in this mode if you want to be able to send an Escape key to
          the website as well. Note that single keys can't be bound in this
          mode.

        `command`
        : Entered when pressing the `:` key in order to enter a command. Note
          that single keys can't be bound in this mode.

        `prompt`
        : Entered when there's a prompt to display, like for download
          locations or when invoked from JavaScript.

        `yesno`
        : Entered when there's a yes/no prompt displayed.

        `caret`
        : Entered when pressing the `v` mode, used to select text using the
          keyboard.

        `register`
        : Entered when qutebrowser is waiting for a register name/key for
          commands like `:set-mark`.
      '';
      example = literalExpression ''
        {
          normal = {
            "<Ctrl-v>" = "spawn mpv {url}";
            ",p" = "spawn --userscript qute-pass";
            ",l" = '''config-cycle spellcheck.languages ["en-GB"] ["en-US"]''';
            "<F1>" = mkMerge [
              "config-cycle tabs.show never always"
              "config-cycle statusbar.show in-mode always"
              "config-cycle scrolling.bar never always"
            ];
          };
          prompt = {
            "<Ctrl-y>" = "prompt-yes";
          };
        }
      '';
    };

    quickmarks = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Quickmarks to add to qutebrowser's {file}`quickmarks` file.
        Note that when Home Manager manages your quickmarks, you cannot edit them at runtime.
      '';
      example = literalExpression ''
        {
          nixpkgs = "https://github.com/NixOS/nixpkgs";
          home-manager = "https://github.com/nix-community/home-manager";
        }
      '';
    };

    greasemonkey = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression ''
        [
          (pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/afreakk/greasemonkeyscripts/1d1be041a65c251692ee082eda64d2637edf6444/youtube_sponsorblock.js";
            sha256 = "sha256-e3QgDPa3AOpPyzwvVjPQyEsSUC9goisjBUDMxLwg8ZE=";
          })
          (pkgs.writeText "some-script.js" '''
            // ==UserScript==
            // @name  Some Greasemonkey script
            // ==/UserScript==
          ''')
        ]
      '';
      description = ''
        Greasemonkey userscripts to add to qutebrowser's {file}`greasemonkey`
        directory.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra lines added to qutebrowser {file}`config.py` file.
      '';
    };

    perDomainSettings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = ''
        Options to set, as in `settings` but per domain.
        Refer to {option}`settings` for details.
      '';
      example = literalExpression ''
        {
          "zoom.us" = {
            content = {
              autoplay = true;
              media.audio_capture = true;
              media.video_capture = true;
            };
          };
          "github.com".colors.webpage.darkmode.enabled = false;
        };
      '';
    };
  };

  config =
    let
      qutebrowserConfig = concatStringsSep "\n" (
        [
          (if cfg.loadAutoconfig then "config.load_autoconfig()" else "config.load_autoconfig(False)")
        ]
        ++ map configSet (flattenSettings cfg.settings)
        ++ mapAttrsToList (formatDictLine "c.aliases") cfg.aliases
        ++ mapAttrsToList (formatDictLine "c.url.searchengines") cfg.searchEngines
        ++ mapAttrsToList (formatDictLine "c.bindings.key_mappings") cfg.keyMappings
        ++ lib.optional (!cfg.enableDefaultBindings) "c.bindings.default = {}"
        ++ mapAttrsToList formatKeyBindings cfg.keyBindings
        ++ lib.optional (cfg.extraConfig != "") cfg.extraConfig
        ++ lib.lists.flatten (mapAttrsToList setUrlConfig cfg.perDomainSettings)
      );

      quickmarksFile = lib.optionals (cfg.quickmarks != { }) concatStringsSep "\n" (
        mapAttrsToList formatQuickmarks cfg.quickmarks
      );

      greasemonkeyDir = lib.optionals (
        cfg.greasemonkey != [ ]
      ) pkgs.linkFarmFromDrvs "greasemonkey-userscripts" cfg.greasemonkey;
    in
    mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      home.file.".qutebrowser/config.py" = mkIf pkgs.stdenv.hostPlatform.isDarwin {
        text = qutebrowserConfig;
      };

      home.file.".qutebrowser/quickmarks" =
        mkIf (cfg.quickmarks != { } && pkgs.stdenv.hostPlatform.isDarwin)
          {
            text = quickmarksFile;
          };

      xdg.configFile."qutebrowser/config.py" = mkIf pkgs.stdenv.hostPlatform.isLinux {
        text = qutebrowserConfig;
        onChange = ''
          hash="$(echo -n "$USER" | md5sum | cut -d' ' -f1)"
          socket="''${XDG_RUNTIME_DIR:-/run/user/$UID}/qutebrowser/ipc-$hash"
          if [[ -S $socket ]]; then
            command=${
              lib.escapeShellArg (
                builtins.toJSON {
                  args = [ ":config-source" ];
                  target_arg = null;
                  protocol_version = 1;
                }
              )
            }
            echo "$command" | ${pkgs.socat}/bin/socat -lf /dev/null - UNIX-CONNECT:"$socket"
          fi
          unset hash socket command
        '';
      };

      xdg.configFile."qutebrowser/quickmarks" =
        mkIf (cfg.quickmarks != { } && pkgs.stdenv.hostPlatform.isLinux)
          {
            text = quickmarksFile;
          };

      home.file.".qutebrowser/greasemonkey" =
        mkIf (cfg.greasemonkey != [ ] && pkgs.stdenv.hostPlatform.isDarwin)
          {
            source = greasemonkeyDir;
          };

      xdg.configFile."qutebrowser/greasemonkey" =
        mkIf (cfg.greasemonkey != [ ] && pkgs.stdenv.hostPlatform.isLinux)
          {
            source = greasemonkeyDir;
          };
    };
}
