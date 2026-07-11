{ ... }:
{
  flake.modules.homeManager.codex =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.programs.codex;
    in
    {
      options.my.programs.codex = {
        enable = lib.mkEnableOption "Codex CLI LLM agent";
      };

      config = lib.mkIf cfg.enable {
        programs.codex = {
          enable = true;
          enableMcpIntegration = true;
          context = ../common/AGENTS.md;
          skills = ../common/skills;
        };
      };
    };
}
