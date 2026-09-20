{ ... }:
{
  flake.modules.nixos.bookorbit =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.bookorbit;

      domain = "books.home.natsukium.com";
      port = 3002;
    in
    {
      options.my.services.bookorbit.enable = mkEnableOption "BookOrbit reading platform";

      config = mkIf cfg.enable {
        services.bookorbit = {
          enable = true;
          environment = {
            PORT = port;
            APP_URL = "http://${domain}";
          };
          environmentFile = config.sops.secrets."bookorbit/env".path;
        };

        # The upstream unit sets PrivateUsers=true, which maps only bookorbit's
        # own uid and gid, so a supplementary calibre-web group would be lost
        # inside the namespace. The library is reached through the world-readable
        # bits of /data/books instead, which also stops BookOrbit from rewriting
        # metadata into files that syncthing would push to every peer.
        systemd.services.bookorbit.serviceConfig.ReadOnlyPaths = [ "/data/books" ];

        services.caddy.virtualHosts."http://${domain}".extraConfig = ''
          reverse_proxy localhost:${toString port}
        '';

        sops.secrets."bookorbit/env" = {
          sopsFile = ./secrets.yaml;
        };
      };
    };
}
