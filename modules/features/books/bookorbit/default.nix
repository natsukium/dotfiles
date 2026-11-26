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

      ttsProvider = {
        name = "Irodori-TTS";
        baseUrl = "http://kilimanjaro.tail4108.ts.net:8088/v1";
        model = "irodori-tts";
        voices = [
          {
            id = "narrator";
            name = "ナレーター";
            shortName = "narrator";
            language = "Japanese";
            locale = "ja-JP";
            gender = "Female";
          }
        ];
      };
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

        # BookOrbit keeps TTS providers only in its database. I upsert the row by
        # name so readers' saved voice choices keep pointing at the same id. Voice
        # discovery stays off because Irodori lists voices under `data`, a key
        # BookOrbit does not read, so it would offer an empty list. BookOrbit
        # caches each provider until restart, so the row must land before it
        # starts.
        systemd.services.bookorbit-tts-provider = {
          after = [ "bookorbit-migrate.service" ];
          requires = [ "bookorbit-migrate.service" ];
          before = [ "bookorbit.service" ];
          requiredBy = [ "bookorbit.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = config.services.bookorbit.user;
            Group = config.services.bookorbit.group;
          };
          script = ''
            ${lib.getExe' config.services.postgresql.package "psql"} \
              "${config.services.bookorbit.environment.DATABASE_URL}" \
              --set=ON_ERROR_STOP=1 \
              --set=name=${lib.escapeShellArg ttsProvider.name} \
              --set=url=${lib.escapeShellArg ttsProvider.baseUrl} \
              --set=model=${lib.escapeShellArg ttsProvider.model} \
              --set=voices=${lib.escapeShellArg (builtins.toJSON ttsProvider.voices)} <<'SQL'
            with updated as (
              update tts_providers
              set type = 'openai-compatible', enabled = true, base_url = :'url',
                  default_model = :'model', static_voices = :'voices'::jsonb,
                  supports_voice_discovery = false, updated_at = now()
              where name = :'name'
              returning id
            )
            insert into tts_providers
              (name, type, enabled, base_url, default_model, static_voices,
               supports_voice_discovery, display_order)
            select :'name', 'openai-compatible', true, :'url', :'model', :'voices'::jsonb,
                   false, coalesce((select max(display_order) + 1 from tts_providers), 0)
            where not exists (select 1 from updated);
            SQL
          '';
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
