{ ... }:
{
  flake.modules.nixos.alertmanager =
    { config, lib, ... }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.alertmanager;

      # matrix-alertmanager relays Alertmanager webhooks to Matrix; everything
      # stays on loopback, so nothing opens a port.
      relayPort = 9088;
    in
    {
      options.my.services.alertmanager.enable =
        mkEnableOption "Prometheus Alertmanager routed to a Matrix room";

      config = mkIf cfg.enable {
        services.prometheus.alertmanager = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = 9093;
          environmentFile = config.sops.templates."alertmanager.env".path;
          configuration = {
            route = {
              receiver = "matrix";
              group_by = [
                "alertname"
                "instance"
              ];
              group_wait = "30s";
              group_interval = "5m";
              # Re-notify a still-firing alert at most once a day so a
              # long-running condition does not flood the room.
              repeat_interval = "24h";
            };
            receivers = [
              {
                name = "matrix";
                webhook_configs = [
                  {
                    # $WEBHOOK_SECRET comes from environmentFile via the module's
                    # envsubst pass, keeping the secret out of the Nix store.
                    url = "http://127.0.0.1:${toString relayPort}/alerts?secret=$WEBHOOK_SECRET";
                    send_resolved = true;
                  }
                ];
              }
            ];
          };
        };

        # Alertmanager lives under services.prometheus only because that is
        # where nixpkgs files it; the unit needs no Prometheus server. vmalert
        # evaluates the rules, so vmalert gets the delivery address.
        services.vmalert.instances.main.settings."notifier.url" = [
          "http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}"
        ];

        services.matrix-alertmanager = {
          enable = true;
          homeserverUrl = "https://matrix.natsukium.com";
          matrixUser = "@alertmanager:natsukium.com";
          port = relayPort;
          matrixRooms = [
            {
              receivers = [ "matrix" ];
              roomId = "!u6NXqeMaNGruayKuPHk8hFMn8_zFpcLIH9_PdugaDhM";
            }
          ];
          tokenFile = config.sops.secrets.matrix-alertmanager-token.path;
          secretFile = config.sops.secrets.matrix-alertmanager-webhook-secret.path;
        };

        sops.secrets.matrix-alertmanager-token.sopsFile = ./secrets.yaml;
        sops.secrets.matrix-alertmanager-webhook-secret.sopsFile = ./secrets.yaml;
        sops.templates."alertmanager.env".content = ''
          WEBHOOK_SECRET=${config.sops.placeholder.matrix-alertmanager-webhook-secret}
        '';
      };
    };
}
