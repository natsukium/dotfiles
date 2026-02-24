{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.opencode;
  commonLib = import ../common/lib.nix { inherit pkgs; };
in
{
  options.my.programs.opencode = {
    enable = lib.mkEnableOption "opencode LLM agent";
  };

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;

      settings = {
        instructions = [ "CLAUDE.md" ];

        autoupdate = false;

        theme = "nord";
      };
    };

    xdg.configFile."opencode/AGENTS.md".source = commonLib.rulesWithTools;

    home.sessionVariables.OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
  };
}
