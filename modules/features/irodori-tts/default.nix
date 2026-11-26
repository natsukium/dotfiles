{ ... }:
{
  flake.modules.nixos.irodori-tts =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
      cfg = config.my.services.irodori-tts;

      port = 8088;
      upstreamPort = 8089;
      stateDir = "/var/lib/irodori-tts";

      src = pkgs.fetchFromGitHub {
        owner = "Aratako";
        repo = "Irodori-TTS-Server";
        rev = "b3c34e13f1c5a0c064bb8922e040c32e26dc6d1d";
        hash = "sha256-W+zQFC6wqb1tZuNsQkQ2ZNAf1dImjYAtJMCkvXRPH0g=";
      };
      image = "irodori-tts:${builtins.substring 0 12 src.rev}";
      docker = lib.getExe config.virtualisation.docker.package;
    in
    {
      options.my.services.irodori-tts.enable =
        mkEnableOption "Irodori-TTS OpenAI-compatible speech server";

      config = mkIf cfg.enable {
        virtualisation.docker.enable = true;
        virtualisation.oci-containers.backend = "docker";

        # Upstream publishes no image, only a Dockerfile, so I build it from the
        # pinned source. The tag carries the revision, so bumping the source
        # rebuilds the image and an unchanged one is reused across boots.
        systemd.services.irodori-tts-image = {
          after = [
            "docker.service"
            "network-online.target"
          ];
          requires = [ "docker.service" ];
          wants = [ "network-online.target" ];
          environment.DOCKER_BUILDKIT = "1";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            TimeoutStartSec = "1h";
          };
          script = ''
            ${docker} image inspect ${image} >/dev/null 2>&1 \
              || ${docker} build --build-arg IRODORI_TTS_BACKEND=cu128 -t ${image} ${src}
          '';
        };

        systemd.services."docker-irodori-tts" = {
          after = [ "irodori-tts-image.service" ];
          requires = [ "irodori-tts-image.service" ];
        };

        virtualisation.oci-containers.containers.irodori-tts = {
          inherit image;
          pull = "never";
          devices = [ "nvidia.com/gpu=all" ];
          # Only the speed proxy talks to the server, so it binds loopback.
          extraOptions = [ "--network=host" ];
          environment = {
            IRODORI_HOST = "127.0.0.1";
            IRODORI_PORT = toString upstreamPort;
            IRODORI_HF_CHECKPOINT = "Aratako/Irodori-TTS-v4.1-Small-MF";
            # The checkpoint's default of 4 steps drops or garbles words in about
            # one paragraph in six. 8 steps reads as accurately as the 40-step RF
            # model at a fraction of its cost.
            IRODORI_DEFAULT_NUM_STEPS = "8";
            IRODORI_MODEL_DEVICE = "cuda";
            IRODORI_CODEC_DEVICE = "cuda";
            IRODORI_MODEL_PRECISION = "bf16";
            IRODORI_CODEC_PRECISION = "bf16";
            IRODORI_VOICES_DIR = "/app/voices";
          };
          volumes = [
            "${stateDir}/huggingface:/root/.cache/huggingface"
            "${stateDir}/voices:/app/voices"
          ];
        };

        # OpenAI clients such as BookOrbit pick a voice by id and cannot pass a
        # Voice Design caption, so I design one narrator once and keep it as a
        # reference clip. The seed is random, so an existing clip is never
        # regenerated.
        systemd.services.irodori-tts-narrator = {
          after = [ "docker-irodori-tts.service" ];
          requires = [ "docker-irodori-tts.service" ];
          wantedBy = [ "docker-irodori-tts.service" ];
          unitConfig.ConditionPathExists = "!${stateDir}/voices/narrator.wav";
          path = [ pkgs.curl ];
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "1h";
          };
          script = ''
            until curl -sf http://127.0.0.1:${toString upstreamPort}/health >/dev/null; do sleep 5; done
            curl -sf http://127.0.0.1:${toString upstreamPort}/v1/audio/speech \
              -H 'Content-Type: application/json' \
              -o ${stateDir}/voices/narrator.wav.tmp \
              -d @${
                pkgs.writeText "narrator.json" (
                  builtins.toJSON {
                    model = "irodori-tts";
                    voice = "none";
                    response_format = "wav";
                    input = "本日は、これから一冊の物語をゆっくりと読んでまいります。どうぞ肩の力を抜いて、お聴きください。";
                    irodori.caption = "落ち着いた中低音の女性の声。穏やかで丁寧な朗読。";
                  }
                )
              }
            mv ${stateDir}/voices/narrator.wav.tmp ${stateDir}/voices/narrator.wav
          '';
        };

        # Irodori honours the OpenAI `speed` field by shrinking the predicted
        # duration, which garbles most sentences at 2x. BookOrbit sends its
        # playback speed there instead of changing the playback rate, so the
        # proxy synthesizes at 1x and time-stretches the result with ffmpeg,
        # which stays intelligible up to 2x and beyond.
        systemd.services.irodori-tts-speed-proxy = {
          after = [ "docker-irodori-tts.service" ];
          wants = [ "docker-irodori-tts.service" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            LISTEN_HOST = "0.0.0.0";
            LISTEN_PORT = toString port;
            UPSTREAM = "http://127.0.0.1:${toString upstreamPort}";
            FFMPEG = lib.getExe pkgs.ffmpeg-headless;
          };
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.python3} -I ${./speed-proxy.py}";
            DynamicUser = true;
            Restart = "on-failure";
          };
        };

        systemd.tmpfiles.settings.irodori-tts = {
          "${stateDir}/huggingface".d = { };
          "${stateDir}/voices".d = { };
        };
      };
    };
}
