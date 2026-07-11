# This file is auto-generated from configuration.org.
# Do not edit directly.

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.forgejo-runner;
  settingsFormat = pkgs.formats.yaml { };

  instanceModule =
    { name, ... }:
    {
      options = {
        enable = lib.mkEnableOption "this runner instance";

        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          defaultText = lib.literalExpression "the attribute name";
          description = "Name the runner registers under.";
        };

        url = lib.mkOption {
          type = lib.types.str;
          example = "https://git.example.com";
          description = "Address of the Forgejo instance the runner registers with.";
        };

        token = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = ''
            Registration token as a plaintext string. Mutually exclusive with
            {option}`tokenFile`. Prefer {option}`tokenFile`: a token set here ends
            up in the world-readable launchd plist and the Nix store.
          '';
        };

        tokenFile = lib.mkOption {
          type = lib.types.nullOr (lib.types.either lib.types.str lib.types.path);
          default = null;
          description = ''
            Path to an environment file holding the registration token as
            `TOKEN=...`. Mutually exclusive with {option}`token`. The token is read
            on first registration and whenever it or {option}`labels` change;
            otherwise the persisted {file}`.runner` credential in {option}`stateDir`
            is used.
          '';
        };

        labels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          example = [ "macos:host" ];
          description = "Labels the runner advertises.";
        };

        settings = lib.mkOption {
          type = settingsFormat.type;
          default = { };
          description = ''
            Runner configuration written to {file}`config.yaml` and passed to the
            daemon with `--config`.
          '';
        };

        hostPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            bash
            coreutils
            curl
            gawk
            gitMinimal
            gnused
            nodejs
            wget
          ];
          defaultText = lib.literalExpression ''
            with pkgs; [ bash coreutils curl gawk gitMinimal gnused nodejs wget ]
          '';
          description = ''
            Packages put on PATH for host-executed jobs. Host jobs inherit only
            the daemon's PATH, so every tool a workflow expects must be listed.
          '';
        };

        stateDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/forgejo-runner/${name}";
          defaultText = lib.literalExpression ''"/var/lib/forgejo-runner/<name>"'';
          description = "Directory holding the runner credential and working files.";
        };
      };
    };

  enabledInstances = lib.filterAttrs (_: i: i.enable) cfg.instances;
in
{
  options.services.forgejo-runner = {
    package = lib.mkPackageOption pkgs "forgejo-runner" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = "_forgejo-runner";
      description = "Dedicated unprivileged user the runner daemons execute as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "_forgejo-runner";
      description = "Primary group for the runner user.";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 530;
      description = "UID for the runner user (free system-range id on the host).";
    };

    gid = lib.mkOption {
      type = lib.types.int;
      default = 530;
      description = "GID for the runner group.";
    };

    instances = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule instanceModule);
      default = { };
      description = "Runner instances; each enabled one becomes a launchd daemon.";
    };
  };

  config = lib.mkIf (enabledInstances != { }) {
    assertions = lib.mapAttrsToList (_: instance: {
      assertion = (instance.token == null) != (instance.tokenFile == null);
      message = "services.forgejo-runner.instances.${instance.name}: set exactly one of token or tokenFile.";
    }) enabledInstances;

    launchd.daemons = lib.mapAttrs' (
      _: instance:
      let
        configFile = settingsFormat.generate "config.yaml" instance.settings;
      in
      lib.nameValuePair "forgejo-runner-${instance.name}" {
        script = ''
          set -eu
          mkdir -p ${lib.escapeShellArg instance.stateDir}
          cd ${lib.escapeShellArg instance.stateDir}
          ${lib.optionalString (instance.tokenFile != null) ''
            set -a
            . ${lib.escapeShellArg (toString instance.tokenFile)}
            set +a
          ''}
          labels=${lib.escapeShellArg (lib.concatStringsSep "," instance.labels)}
          state="$(printf '%s' "$TOKEN" | sha256sum | cut -d' ' -f1) $labels"

          if [ ! -f .runner ] || [ "$(cat .registration-state 2>/dev/null)" != "$state" ]; then
            rm -f .runner
            ${lib.getExe cfg.package} register \
              --no-interactive \
              --instance ${lib.escapeShellArg instance.url} \
              --token "$TOKEN" \
              --name ${lib.escapeShellArg instance.name} \
              --labels "$labels" \
              --config ${configFile}
            printf '%s' "$state" > .registration-state
          fi

          exec ${lib.getExe cfg.package} daemon --config ${configFile}
        '';
        serviceConfig = {
          UserName = cfg.user;
          GroupName = cfg.group;
          KeepAlive = true;
          RunAtLoad = true;
          ProcessType = "Background";
          EnvironmentVariables = {
            HOME = instance.stateDir;
            PATH = "${
              lib.makeBinPath ([ pkgs.coreutils ] ++ instance.hostPackages)
            }:/usr/bin:/bin:/usr/sbin:/sbin";
          }
          // lib.optionalAttrs (instance.token != null) { TOKEN = instance.token; };
          StandardOutPath = "${instance.stateDir}/forgejo-runner.log";
          StandardErrorPath = "${instance.stateDir}/forgejo-runner.err.log";
        };
      }
    ) enabledInstances;

    users.users.${cfg.user} = {
      uid = cfg.uid;
      gid = cfg.gid;
      isHidden = true;
      description = "Forgejo Actions runner";
    };
    users.groups.${cfg.group}.gid = cfg.gid;
    users.knownUsers = [ cfg.user ];
    users.knownGroups = [ cfg.group ];

    system.activationScripts.launchd.text = lib.mkBefore (
      lib.concatMapStringsSep "\n" (instance: ''
        mkdir -p ${lib.escapeShellArg instance.stateDir}
        chown -R ${lib.escapeShellArg cfg.user}:${lib.escapeShellArg cfg.group} ${lib.escapeShellArg instance.stateDir}
      '') (lib.attrValues enabledInstances)
    );
  };
}
