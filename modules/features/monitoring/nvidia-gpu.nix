{ inputs, ... }:
{
  # The exporter belongs to the machine with the card, but the scrape config and
  # the alerts belong to the machine that watches the fleet, so both halves live
  # here and each switches itself on where it applies.
  flake.modules.nixos.nvidia-gpu-metrics =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib) mkIf mkOption types;
      cfg = config.my.services.nvidia-gpu-metrics;
      vm = config.my.services.victoriametrics;

      gpuTarget =
        name: value:
        let
          inherit (value.config.services.prometheus.exporters.nvidia-gpu) listenAddress port;
        in
        "${if name == config.networking.hostName then listenAddress else name}:${toString port}";

      # Tied to the node scrape set: a GPU temperature I cannot line up against
      # the same host's CPU and fan story is not something I can act on.
      gpuMachines = lib.filterAttrs (
        name: value:
        builtins.elem name vm.nodeMetricsHosts && value.config.my.services.nvidia-gpu-metrics.enable
      ) inputs.self.outputs.nixosConfigurations;
    in
    {
      options.my.services.nvidia-gpu-metrics.enable = mkOption {
        type = types.bool;
        default = config.hardware.nvidia.enabled;
        defaultText = lib.literalExpression "config.hardware.nvidia.enabled";
        description = "Whether to export this host's NVIDIA GPU metrics.";
      };

      config = lib.mkMerge [
        (mkIf cfg.enable {
          services.prometheus.exporters.nvidia-gpu.enable = true;
        })

        (mkIf vm.enable {
          services.victoriametrics.prometheusConfig.scrape_configs = [
            {
              job_name = "nvidia-gpu";
              static_configs = [ { targets = lib.mapAttrsToList gpuTarget gpuMachines; } ];
            }
          ];

          services.vmalert.instances.main.rules.groups = [
            {
              name = "nvidia-gpu";
              rules = [
                {
                  # The 3080 throttles itself at 83C and a long game or CUDA
                  # build sits there legitimately, so the alert is set above
                  # the throttle point where the cause is airflow, not load.
                  alert = "GpuTemperatureHigh";
                  expr = "nvidia_smi_temperature_gpu > 88";
                  for = "15m";
                  labels.severity = "warning";
                  annotations.summary = ''GPU on {{ $labels.instance }} at {{ printf "%.0f" $value }}C'';
                }
                {
                  # The exporter shells out to nvidia-smi, which fails when the
                  # kernel module and the userspace driver drift apart after an
                  # upgrade. The host stays up, so nothing else would say the
                  # GPU has been unusable since the last reboot.
                  alert = "GpuMetricsUnavailable";
                  expr = "nvidia_smi_last_collect_success == 0";
                  for = "15m";
                  labels.severity = "warning";
                  annotations.summary = "nvidia-smi is failing on {{ $labels.instance }}";
                }
              ];
            }
          ];
        })
      ];
    };
}
