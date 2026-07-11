{ ... }:
{
  flake.modules.homeManager.antigravity-cli =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.programs.antigravity-cli;
    in
    {
      options.my.programs.antigravity-cli = {
        enable = lib.mkEnableOption "Antigravity CLI LLM agent";
      };

      config = lib.mkIf cfg.enable {
        programs.antigravity-cli = {
          enable = true;

          context.AGENTS = ../common/AGENTS.md;

          skills = ../common/skills;

          settings = {
            selectedAuthType = "oauth-personal";

            general = {
              disableAutoUpdate = true;
              disableUpdateNag = true;
            };

            ui = {
              showMemoryUsage = true;
            };

            context.fileName = [
              "AGENTS.md"
              "CLAUDE.md"
            ];

            mcpServers = config.programs.mcp.servers;
          };
        };
      };
    };
}
