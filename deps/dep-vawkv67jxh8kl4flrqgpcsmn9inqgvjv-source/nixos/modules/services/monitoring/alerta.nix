{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.alerta;

  alertaConf = pkgs.writeTextFile {
    name = "alertad.conf";
    text = ''
      DATABASE_URL = '${cfg.databaseUrl}'
      DATABASE_NAME = '${cfg.databaseName}'
      LOG_FILE = '${cfg.logDir}/alertad.log'
      LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
      CORS_ORIGINS = [ ${concatMapStringsSep ", " (s: "\"" + s + "\"") cfg.corsOrigins} ];
      AUTH_REQUIRED = ${if cfg.authenticationRequired then "True" else "False"}
      SIGNUP_ENABLED = ${if cfg.signupEnabled then "True" else "False"}
      ${cfg.extraConfig}
    '';
  };
in
{
  options.services.alerta = {
    enable = mkEnableOption "alerta";

    port = mkOption {
      type = types.port;
      default = 5000;
      description = "Port of Alerta";
    };

    bind = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to bind to. The default is to bind to all addresses";
    };

    logDir = mkOption {
      type = types.path;
      description = "Location where the logfiles are stored";
      default = "/var/log/alerta";
    };

    databaseUrl = mkOption {
      type = types.str;
      description = "URL of the MongoDB or PostgreSQL database to connect to";
      default = "mongodb://localhost";
    };

    databaseName = mkOption {
      type = types.str;
      description = "Name of the database instance to connect to";
      default = "monitoring";
    };

    corsOrigins = mkOption {
      type = types.listOf types.str;
      description = "List of URLs that can access the API for Cross-Origin Resource Sharing (CORS)";
      default = [
        "http://localhost"
        "http://localhost:5000"
      ];
    };

    authenticationRequired = mkOption {
      type = types.bool;
      description = "Whether users must authenticate when using the web UI or command-line tool";
      default = false;
    };

    signupEnabled = mkOption {
      type = types.bool;
      description = "Whether to prevent sign-up of new users via the web UI";
      default = true;
    };

    extraConfig = mkOption {
      description = "These lines go into alertad.conf verbatim.";
      default = "";
      type = types.lines;
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.settings."10-alerta".${cfg.logDir}.d = {
      user = "alerta";
      group = "alerta";
    };

    systemd.services.alerta = {
      description = "Alerta Monitoring System";
      wantedBy = [ "multi-user.target" ];
      after = [ "networking.target" ];
      environment = {
        ALERTA_SVR_CONF_FILE = alertaConf;
      };
      serviceConfig = {
        ExecStart = "${pkgs.alerta-server}/bin/alertad run --port ${toString cfg.port} --host ${cfg.bind}";
        User = "alerta";
        Group = "alerta";
      };
    };

    environment.systemPackages = [ pkgs.alerta ];

    users.users.alerta = {
      uid = config.ids.uids.alerta;
      description = "Alerta user";
    };

    users.groups.alerta = {
      gid = config.ids.gids.alerta;
    };
  };
}
