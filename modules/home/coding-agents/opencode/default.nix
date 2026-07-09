{
  config,
  lib,
  ...
}:
let
  cfg = config.my.programs.opencode;
in
{
  options.my.programs.opencode = {
    enable = lib.mkEnableOption "opencode LLM agent";
  };

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;

      context = ../common/AGENTS.md;

      skills = ../common/skills;

      settings = {
        instructions = [ "CLAUDE.md" ];

        autoupdate = false;
      };

      tui = {
        theme = "nord";
      };
    };

    home.sessionVariables.OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
  };
}
