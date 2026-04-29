{ config, ... }:
let
  hostname = config.networking.hostName;
in
{
  # The guest's journald forwards to ttyS0 (see guest.nix
  # services.journald.extraConfig), and microvm.nix's host-side
  # microvm@<name>.service captures that console stream into the host journal.
  # Tapping that single unit therefore yields both the qemu/microvm runner's
  # own messages and hermes-agent's application logs without needing alloy
  # inside the VM.
  #
  # Forwards to loki.write.default.receiver, which is defined by the comin
  # alloy snippet (systems/shared/comin/alloy.nix) that is already imported
  # via systems/common.nix. Component names are scoped per .alloy file but
  # exported receivers are visible across the directory.
  my.services.alloy.configs.hermes-agent = ''
    loki.relabel "hermes_agent" {
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

    loki.source.journal "hermes_agent" {
      forward_to = [loki.relabel.hermes_agent.receiver]
      matches    = "_SYSTEMD_UNIT=microvm@hermes-agent.service"
      labels     = {
        job  = "hermes-agent",
        host = "${hostname}",
        os   = "linux",
      }
    }
  '';
}
