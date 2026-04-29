{ config, ... }:
let
  hostname = config.networking.hostName;
in
{
  # Tapping microvm@hermes-agent.service alone is enough: the guest's journald
  # forwards to ttyS0, which microvm.nix's host-side unit captures into the
  # host journal — so we get both runner and application logs without an
  # in-VM alloy. loki.write.default.receiver comes from the comin alloy
  # snippet shared via systems/common.nix.
  my.services.alloy.configs.hermes-agent = ''
    loki.source.journal "hermes_agent" {
      forward_to = [loki.write.default.receiver]
      matches    = "_SYSTEMD_UNIT=microvm@hermes-agent.service"
      labels     = {
        job  = "hermes-agent",
        host = "${hostname}",
        os   = "linux",
      }
    }
  '';
}
