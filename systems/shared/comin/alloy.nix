{
  config,
  inputs,
  pkgs,
  ...
}:
let
  hostname = config.networking.hostName;

  # Reached over Tailscale MagicDNS via the full tailnet FQDN; the short
  # name "manyara" resolves to only an IPv6 ULA on Linux and is bypassed by
  # macOS resolvers (Tailscale does not intercept /etc/resolv.conf-based
  # tools), both of which made Alloy push retries log status_code=-1. The
  # FQDN form is stable in both resolvers.
  lokiPort =
    inputs.self.outputs.nixosConfigurations.manyara.config.services.loki.configuration.server.http_listen_port;
  endpoint = "http://manyara.tail4108.ts.net:${toString lokiPort}/loki/api/v1/push";

  writeBlock = ''
    loki.write "default" {
      endpoint {
        url = "${endpoint}"
      }
    }'';

  alloyConfig =
    if pkgs.stdenv.hostPlatform.isDarwin then
      # Tail only the live file. Rotated archives are gzipped (`flags = [ "Z" ]`
      # in my.services.newsyslog), and loki.source.file does NOT decompress
      # transparently — it would forward gzip bytes verbatim and pollute Loki
      # with garbled lines. We do not need to read archives anyway: Alloy uses
      # fsevents to follow rename events and reads each rotated file to EOF
      # before closing its handle, so by the time newsyslog finishes gzipping
      # the renamed file, Alloy has already shipped its contents.
      ''
        local.file_match "comin" {
          path_targets = [{
            __path__ = "${config.launchd.daemons.comin.serviceConfig.StandardOutPath}",
            job      = "comin",
            host     = "${hostname}",
            os       = "darwin",
          }]
        }

        loki.process "comin" {
          forward_to = [loki.write.default.receiver]

          // comin emits logfmt on Linux; on Darwin the launchd-captured stdout
          // is the same payload but framed without journald metadata.
          stage.logfmt {
            mapping = {
              "level" = "",
              "msg"   = "",
            }
          }
          stage.labels {
            values = {
              level = "",
            }
          }
        }

        loki.source.file "comin" {
          targets    = local.file_match.comin.targets
          forward_to = [loki.process.comin.receiver]
          // The comin log file accumulates between newsyslog rotations, so on
          // a fresh Alloy install it may already contain weeks of history
          // older than Loki's reject_old_samples_max_age (default 168h). Without
          // this flag, every existing line is shipped and dropped by the
          // ingester with reason="ingester_error". Tail-from-end is the standard
          // log-shipper pattern (loki.source.journal already does this via
          // from_init=false by default); positions.yml takes over after the
          // first start.
          tail_from_end = true
        }

        ${writeBlock}
      ''
    else
      # Filter on _SYSTEMD_UNIT at the journal level rather than via a relabel
      # rule so non-comin entries are never read into memory.
      ''
        loki.relabel "comin" {
          forward_to = [loki.write.default.receiver]

          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }
          rule {
            source_labels = ["__journal_priority_keyword"]
            target_label  = "level"
          }
        }

        loki.source.journal "comin" {
          forward_to = [loki.relabel.comin.receiver]
          matches    = "_SYSTEMD_UNIT=comin.service"
          labels     = {
            job  = "comin",
            host = "${hostname}",
            os   = "linux",
          }
        }

        ${writeBlock}
      '';
in
{
  my.services.alloy = {
    enable = true;
    configs.comin = alloyConfig;
  };
}
