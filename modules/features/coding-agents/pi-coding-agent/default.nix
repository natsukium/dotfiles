{ ... }:
{
  flake.modules.homeManager.pi-coding-agent =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.programs.pi-coding-agent;
    in
    {
      options.my.programs.pi-coding-agent = {
        enable = lib.mkEnableOption "pi coding agent CLI";
      };

      config = lib.mkIf cfg.enable {
        programs.pi-coding-agent = {
          enable = true;
          configDir = "${config.xdg.configHome}/pi/agent";
          context = ../common/AGENTS.md;
        };

        # Reuse repo-local Claude skills in pi instead of maintaining parallel
        # .agents/skills copies.
        home.file."${config.programs.pi-coding-agent.configDir}/extensions/claude-project-skills.ts".source =
          ./extensions/claude-project-skills.ts;
      };
    };
}
