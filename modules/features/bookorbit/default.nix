{ ... }:
{
  flake.modules.nixos.bookorbit =
    {
      config,
      lib,
      pkgs,
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
        systemd.services.bookorbit = {
          serviceConfig.ReadOnlyPaths = [ "/data/books" ];

          # BookOrbit shells out to pdftoppm for PDF covers and to ffmpeg for
          # audiobooks, but the nixpkgs package lists ffmpeg as a build input
          # and wraps the binary without a PATH prefix, so neither reaches the
          # running service. Every PDF import fails with
          # code=cover-extraction-failed and a bare "spawn pdftoppm ENOENT".
          path = with pkgs; [
            poppler-utils
            ffmpeg
          ];
        };

        services.caddy.virtualHosts."http://${domain}".extraConfig = ''
          reverse_proxy localhost:${toString port}
        '';

        sops.secrets."bookorbit/env" = {
          sopsFile = ./secrets.yaml;
        };
      };
    };
}
