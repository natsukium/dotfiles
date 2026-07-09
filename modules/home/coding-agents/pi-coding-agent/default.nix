{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.pi-coding-agent;
  commonLib = import ../common/lib.nix { inherit pkgs; };
in
{
  options.my.programs.pi-coding-agent = {
    enable = lib.mkEnableOption "pi coding agent CLI";
  };

  config = lib.mkIf cfg.enable {
    programs.pi-coding-agent = {
      enable = true;
      configDir = "${config.xdg.configHome}/pi/agent";
      context = commonLib.rulesWithTools;
    };
  };
}
