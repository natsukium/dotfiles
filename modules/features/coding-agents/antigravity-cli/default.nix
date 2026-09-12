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
        # Antigravity CLI rewrites this file to record trustedWorkspaces.
        # backupFileExtension keeps only one backup, so the second rewrite
        # leaves nowhere to move the file and activation fails.
        home.file.".gemini/antigravity-cli/settings.json".force = true;

        programs.antigravity-cli = {
          enable = true;

          context.AGENTS = ../common/AGENTS.md;

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
