{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.blueman-applet;
in
{
  options = {
    services.blueman-applet = {
      enable = lib.mkEnableOption "" // {
        description = ''
          Whether to enable the Blueman applet.

          Note that for the applet to work, the `blueman` service should
          be enabled system-wide. You can enable it in the system
          configuration using
          ```nix
          services.blueman.enable = true;
          ```
        '';
      };

      package = lib.mkPackageOption pkgs "blueman" { };
    };
  };

  config = lib.mkIf config.services.blueman-applet.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.blueman-applet" pkgs lib.platforms.linux)
    ];

    systemd.user.services.blueman-applet = {
      Unit = {
        Description = "Blueman applet";
        Requires = [ "tray.target" ];
        After = [
          "graphical-session.target"
          "tray.target"
        ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${lib.getExe' cfg.package "blueman-applet"}";
      };
    };
  };
}
