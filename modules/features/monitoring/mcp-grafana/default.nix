{ ... }:
{
  flake.modules.nixos.mcp-grafana =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.mcp-grafana;

      domain = "mcp.home.natsukium.com";
      inherit (cfg) ports;

      # The hermes-agent guest has SLIRP networking, where the gateway forwards
      # to the host's loopback (the same route its SearXNG backend takes). Host
      # validation otherwise only accepts the loopback spelling of -address.
      guestGateway = "10.0.2.2";

      mkInstance =
        {
          variant,
          allowedHost,
          extraArgs ? [ ],
        }:
        {
          description = "MCP server for Grafana (${variant})";
          wantedBy = [ "multi-user.target" ];
          after = [ "grafana.service" ];
          environment.GRAFANA_URL = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
          serviceConfig = {
            ExecStart = lib.concatStringsSep " " (
              [
                (lib.getExe pkgs.mcp-grafana)
                "-transport streamable-http"
                "-address 127.0.0.1:${toString ports.${variant}}"
                "-allowed-hosts ${allowedHost}"
              ]
              ++ extraArgs
            );
            # Read by PID 1, so the rendered secrets stay root-only while the
            # service itself runs unprivileged.
            EnvironmentFile = config.sops.templates."mcp-grafana-${variant}.env".path;
            DynamicUser = true;
            Restart = "on-failure";
            CapabilityBoundingSet = [ "" ];
            NoNewPrivileges = true;
            PrivateDevices = true;
            ProtectHome = true;
            ProtectSystem = "strict";
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "~@privileged"
            ];
          };
        };

      # The service account token carries my Grafana permissions and the server
      # token is the only thing standing between the network and them, so both
      # reach the process as environment variables rather than argv, which any
      # local process could read out of /proc.
      mkEnv = variant: {
        content = ''
          GRAFANA_SERVICE_ACCOUNT_TOKEN=${
            config.sops.placeholder."mcp-grafana-${variant}-service-account-token"
          }
          MCP_GRAFANA_SERVER_TOKEN=${config.sops.placeholder."mcp-grafana-${variant}-server-token"}
        '';
      };

      mkSecrets =
        variant:
        lib.genAttrs
          [
            "mcp-grafana-${variant}-service-account-token"
            "mcp-grafana-${variant}-server-token"
          ]
          (_: {
            sopsFile = ./secrets.yaml;
          });
    in
    {
      # Running the server next to Grafana keeps the credentials on the host that
      # already holds them: every client then needs a URL instead of its own copy
      # of a Grafana login.
      options.my.services.mcp-grafana = {
        enable = mkEnableOption "the Grafana MCP server";

        # The hermes-agent guest composes its own URL against the read-only
        # instance, so the ports are options rather than private let-bindings.
        ports = {
          rw = lib.mkOption {
            type = lib.types.port;
            default = 3021;
            description = "Port of the writable instance.";
          };
          ro = lib.mkOption {
            type = lib.types.port;
            default = 3022;
            description = "Port of the read-only instance.";
          };
        };
      };

      config = mkIf cfg.enable {
        # Two instances rather than one, because hermes runs unattended: it gets
        # the read-only endpoint so a conversation can never rewrite a dashboard
        # or silence an alert, while my own sessions in the dotfiles repo keep
        # the writable one. The split is enforced twice over -- the flags hide
        # the write tools, and a Viewer service account token makes Grafana
        # reject the calls even if a future flag change exposed them again.
        systemd.services = {
          mcp-grafana-rw = mkInstance {
            variant = "rw";
            allowedHost = domain;
          };
          mcp-grafana-ro = mkInstance {
            variant = "ro";
            allowedHost = "${guestGateway}:${toString ports.ro}";
            extraArgs = [
              "-disable-write"
              "-disable-admin"
            ];
          };
        };

        # Only the writable instance is published: hermes dials the read-only one
        # straight through the SLIRP gateway, so leaving it off caddy keeps it
        # off the LAN entirely.
        services.caddy.virtualHosts."http://${domain}".extraConfig = ''
          reverse_proxy localhost:${toString ports.rw}
        '';

        sops.secrets = mkSecrets "rw" // mkSecrets "ro";
        sops.templates = {
          "mcp-grafana-rw.env" = mkEnv "rw";
          "mcp-grafana-ro.env" = mkEnv "ro";
        };
      };
    };
}
