{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.antigravity-cli;
  commonLib = import ../common/lib.nix { inherit pkgs; };
in
{
  options.my.programs.antigravity-cli = {
    enable = lib.mkEnableOption "Antigravity CLI LLM agent";
  };

  config = lib.mkIf cfg.enable {
    programs.antigravity-cli = {
      enable = true;

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

    home.file.".antigravity-cli/AGENTS.md".source = commonLib.rulesWithTools;
  };
}
