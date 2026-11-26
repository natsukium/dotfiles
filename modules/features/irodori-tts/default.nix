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
          # Docker's published ports bypass the NixOS firewall and would reach the
          # LAN. On the host network the firewall applies, so only tailscale0,
          # which it trusts, can reach the port.
          extraOptions = [ "--network=host" ];
          environment = {
            IRODORI_HOST = "0.0.0.0";
            IRODORI_PORT = toString port;
            IRODORI_HF_CHECKPOINT = "Aratako/Irodori-TTS-v4.1-Small-MF";
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

        systemd.tmpfiles.settings.irodori-tts = {
          "${stateDir}/huggingface".d = { };
          "${stateDir}/voices".d = { };
        };
      };
    };
}
