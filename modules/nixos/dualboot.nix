{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.dualboot;
in
{
  options = with types; {
    dualboot = {
      enable = mkEnableOption "Enable dualboot with Windows";
      ntfsSupport = mkOption {
        type = bool;
        default = true;
        description = ''
          Enable NTFS support in the kernel. This is required to read and write to NTFS partitions.
        '';
      };
      adjustClock = mkOption {
        type = bool;
        default = true;
        description = ''
          Set the hardware clock to local time. This is required for Windows to display the correct time.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    boot.supportedFilesystems = optionals cfg.ntfsSupport [ "ntfs" ];
    time.hardwareClockInLocalTime = cfg.adjustClock;
  };
}
