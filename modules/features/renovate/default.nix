{ ... }:
{
  flake.modules.nixos.renovate =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        concatMapStrings
        mapAttrs'
        mapAttrsToList
        mkEnableOption
        mkIf
        mkOption
        mkPackageOption
        nameValuePair
        optional
        optionalString
        types
        ;
      cfg = config.my.services.renovate;
      json = pkgs.formats.json { };

      # Renovate only reports a bad global config when a run starts, which for a
      # timer-driven service means the next fire; I run its validator at build
      # time so a mistake fails the build instead.
      configFile =
        name: instance:
        let
          settings = {
            # Renovate's default is to download its own toolchain at runtime,
            # which only works inside its Containerbase image.
            binarySource = "global";
            baseDir = "/var/lib/renovate-${name}";
            cacheDir = "/var/cache/renovate-${name}";
          }
          // instance.settings;
        in
        if instance.validateSettings then
          pkgs.runCommand "renovate-${name}-config.json"
            {
              nativeBuildInputs = [
                pkgs.jq
                cfg.package
              ];
              value = builtins.toJSON settings;
              passAsFile = [ "value" ];
              preferLocalBuild = true;
            }
            ''
              jq . "$valuePath" > $out
              renovate-config-validator $out
            ''
        else
          json.generate "renovate-${name}-config.json" settings;

      mkService =
        name: instance:
        nameValuePair "renovate-${name}" {
          description = "Renovate dependency updater (${name})";
          documentation = [ "https://docs.renovatebot.com/" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          startAt = optional (instance.schedule != null) instance.schedule;

          path = [
            config.systemd.package
            pkgs.git
          ]
          ++ optional (instance.githubApp != null) pkgs.gh-token
          ++ instance.runtimePackages;

          environment = {
            RENOVATE_CONFIG_FILE = configFile name instance;
            HOME = "/var/lib/renovate-${name}";
          }
          // instance.environment;

          serviceConfig = {
            Type = "oneshot";
            DynamicUser = true;
            LoadCredential =
              mapAttrsToList (n: v: "SECRET-${n}:${v}") instance.credentials
              ++ optional (instance.githubApp != null) "github-app-key:${instance.githubApp.privateKeyFile}";
            CacheDirectory = "renovate-${name}";
            StateDirectory = "renovate-${name}";

            # Hardening, as in nixpkgs' services.renovate.
            CapabilityBoundingSet = [ "" ];
            DeviceAllow = [ "" ];
            LockPersonality = true;
            PrivateDevices = true;
            PrivateUsers = true;
            ProcSubset = "pid";
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectProc = "invisible";
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            SystemCallArchitectures = "native";
            UMask = "0077";
          };

          script = ''
            ${concatMapStrings (n: ''
              ${n}="$(systemd-creds cat 'SECRET-${n}')"
              export ${n}
            '') (builtins.attrNames instance.credentials)}
            ${optionalString (instance.githubApp != null) ''
              # An installation token expires after an hour, so nothing
              # long-lived has to sit on the host for the bot to authenticate.
              RENOVATE_TOKEN="$(gh-token generate \
                --app-id ${toString instance.githubApp.appId} \
                --key "$CREDENTIALS_DIRECTORY/github-app-key" \
                --token-only)"
              export RENOVATE_TOKEN
            ''}
            exec ${lib.getExe cfg.package}
          '';
        };
    in
    {
      # nixpkgs' services.renovate is a single unit, and `platform` is global to
      # a run: one Renovate process cannot cover both GitHub and a Forgejo
      # instance. So I give each instance its own unit, state and credentials,
      # which also keeps one platform's failure off the other's timer and
      # reports it separately through the failed-unit alert.
      options.my.services.renovate = {
        enable = mkEnableOption "self-hosted Renovate";

        package = mkPackageOption pkgs "renovate" { };

        instances = mkOption {
          default = { };
          description = "Renovate runs on this host, one systemd unit each.";
          type = types.attrsOf (
            types.submodule {
              options = {
                settings = mkOption {
                  type = json.type;
                  default = { };
                  description = ''
                    Renovate's global configuration. Secrets belong in
                    {option}`credentials`, since this ends up in the store.
                  '';
                };

                validateSettings = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Whether to run Renovate's config validator over {option}`settings`.";
                };

                credentials = mkOption {
                  type = types.attrsOf types.path;
                  default = { };
                  description = "Environment variables exported to Renovate, read from files.";
                  example = {
                    RENOVATE_TOKEN = "/run/secrets/renovate-token";
                  };
                };

                githubApp = mkOption {
                  type = types.nullOr (
                    types.submodule {
                      options = {
                        appId = mkOption {
                          type = types.int;
                          description = "Numeric ID of the GitHub App.";
                        };

                        privateKeyFile = mkOption {
                          type = types.path;
                          description = "PEM private key issued for the App.";
                        };
                      };
                    }
                  );
                  default = null;
                  description = ''
                    Mint `RENOVATE_TOKEN` from a GitHub App installation before
                    each run, instead of carrying a personal access token.
                  '';
                };

                runtimePackages = mkOption {
                  type = types.listOf types.package;
                  default = [ ];
                  description = "Packages on Renovate's PATH, for managers and postUpgradeTasks.";
                };

                environment = mkOption {
                  type = types.attrsOf types.str;
                  default = { };
                  description = "Extra environment variables for the unit.";
                  example = {
                    LOG_LEVEL = "debug";
                  };
                };

                schedule = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "How often the run fires. See {manpage}`systemd.time(7)`.";
                  example = "hourly";
                };
              };
            }
          );
        };
      };

      config = mkIf cfg.enable {
        systemd.services = mapAttrs' mkService cfg.instances;

        # The bot's own identity, not any one host's: the App key and the two
        # tokens say who Renovate is on GitHub and on Forgejo, and would follow
        # it unchanged to another machine. I leave which instance authenticates
        # with which to the host declaring the instances.
        sops.secrets = {
          renovate-github-app-key.sopsFile = ./secrets.yaml;
          renovate-forgejo-token.sopsFile = ./secrets.yaml;
          renovate-github-com-token.sopsFile = ./secrets.yaml;
        };
      };
    };
}
