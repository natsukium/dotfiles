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

  pizauthCmd = lib.getExe cfg.package;
  ageCmd = lib.getExe pkgs.age;

  dumpDir = dirOf cfg.persistence.dumpFile;

  tokenEventCmd = lib.optionalString cfg.persistence.enable ''
    token_event_cmd = "mkdir -p ${dumpDir} && ${pizauthCmd} dump | ${ageCmd} -e -R ${cfg.persistence.ageRecipient} -o ${cfg.persistence.dumpFile}";
  '';

  accountsContent = lib.concatStringsSep "\n\n" (
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

  configContent = tokenEventCmd + accountsContent;

  configPath = config.sops.templates."pizauth.conf".path;

  # Wrapper script that starts pizauth and restores persisted tokens.
  # launchd has no ExecStartPost equivalent, so a unified wrapper
  # script is used on both platforms (same pattern as mbsync.nix).
  serverScript = pkgs.writeShellScript "pizauth-server" ''
    set -euo pipefail
    ${pizauthCmd} server -d -c ${configPath} &
    PIZAUTH_PID=$!

    if [ -f "${cfg.persistence.dumpFile}" ]; then
      for _ in $(seq 1 50); do
        ${pizauthCmd} status >/dev/null 2>&1 && break
        sleep 1
      done
      ${ageCmd} -d -i ${cfg.persistence.ageIdentity} ${cfg.persistence.dumpFile} | ${pizauthCmd} restore || true
    fi

    wait "$PIZAUTH_PID"
  '';

  startCmd =
    if cfg.persistence.enable then
      "${serverScript}"
    else
      "${pizauthCmd} server -d -c ${configPath}";
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
    persistence = {
      enable = mkEnableOption "persistence of pizauth tokens via age-encrypted dump";
      ageIdentity = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.ssh/id_ed25519";
        description = "Path to the age identity (private key) for decryption.";
      };
      ageRecipient = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
        description = "Path to the age recipient (public key) for encryption.";
      };
      dumpFile = mkOption {
        type = types.str;
        default = "${config.xdg.dataHome}/pizauth/dump.age";
        description = "Path to the age-encrypted token dump file.";
      };
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
          ProgramArguments = [ startCmd ];
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
          ExecStart = startCmd;
          Restart = "always";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    })
  ]);
}
