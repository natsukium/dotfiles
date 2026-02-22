{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.my.services.pizauth;

  configContent = lib.concatStringsSep "\n\n" (
    lib.mapAttrsToList (
      name: acc:
      let
        authUriFieldsStr =
          if acc.authUriFields != { } then
            "\n    auth_uri_fields = { ${
              lib.concatStringsSep ", " (lib.mapAttrsToList (k: v: ''"${k}": "${v}"'') acc.authUriFields)
            } };"
          else
            "";
      in
      ''
        account "${name}" {
            auth_uri = "${acc.authUri}";
            token_uri = "${acc.tokenUri}";
            client_id = "${config.sops.placeholder.${acc.clientIdSecret}}";
            client_secret = "${config.sops.placeholder.${acc.clientSecretSecret}}";
            scopes = [${lib.concatMapStringsSep ", " (s: ''"${s}"'') acc.scopes}];${authUriFieldsStr}
        }''
    ) cfg.accounts
  );

  configPath = config.sops.templates."pizauth.conf".path;
in
{
  options.my.services.pizauth = {
    enable = mkEnableOption "pizauth OAuth2 token daemon";
    package = mkPackageOption pkgs "pizauth" { };
    accounts = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            authUri = mkOption {
              type = types.str;
              description = "OAuth2 authorization endpoint URI.";
            };
            tokenUri = mkOption {
              type = types.str;
              description = "OAuth2 token endpoint URI.";
            };
            clientIdSecret = mkOption {
              type = types.str;
              description = "Name of the sops secret containing the OAuth2 client ID.";
            };
            clientSecretSecret = mkOption {
              type = types.str;
              description = "Name of the sops secret containing the OAuth2 client secret.";
            };
            scopes = mkOption {
              type = types.listOf types.str;
              description = "OAuth2 scopes to request.";
            };
            authUriFields = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Additional query parameters for the authorization URI.";
            };
          };
        }
      );
      default = { };
      description = "pizauth account configurations.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      sops.templates."pizauth.conf" = {
        content = configContent;
      };
    }

    (mkIf pkgs.stdenv.hostPlatform.isDarwin {
      launchd.agents.pizauth = {
        enable = true;
        config = {
          ProgramArguments = [
            "${lib.getExe cfg.package}"
            "server"
            "-d"
            "-c"
            configPath
          ];
          KeepAlive = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/pizauth/stdout";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/pizauth/stderr";
        };
      };
    })

    (mkIf pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services.pizauth = {
        Unit = {
          Description = "pizauth OAuth2 token daemon";
        };
        Service = {
          ExecStart = "${lib.getExe cfg.package} server -d -c ${configPath}";
          Restart = "always";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    })
  ]);
}
