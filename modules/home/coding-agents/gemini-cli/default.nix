{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.gemini-cli;
  commonLib = import ../common/lib.nix { inherit pkgs; };
in
{
  options.my.programs.gemini-cli = {
    enable = lib.mkEnableOption "Gemini CLI LLM agent";
  };

  config = lib.mkIf cfg.enable {
    programs.gemini-cli = {
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

        mcpServers = import ../common/mcp-servers.nix { inherit inputs pkgs; };
      };
    };

    home.file.".gemini/AGENTS.md".source = commonLib.rulesWithTools;
  };
}
