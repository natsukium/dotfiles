# The skill set shared by every coding agent, and its installation into each one.
#
# Home Manager lets an agent pull shared MCP servers by asking for them
# (`enableMcpIntegration`), but the agent modules are upstream, so a skill
# equivalent cannot be added to them. The set is pushed instead: enabling an
# agent anywhere is enough to install the skills.
#
# Nothing here decides *which* skills exist or which agent wants a smaller set.
# Both are options, so a skill can be contributed by whichever module owns it —
# playwright-cli ships its SKILL.md inside the package — and an agent declines a
# skill in its own module, next to the reason.
{ ... }:
{
  flake.modules.homeManager.coding-agent-skills =
    { config, lib, ... }:
    let
      cfg = config.my.programs.coding-agents;

      skillsIn =
        dir:
        lib.genAttrs (lib.attrNames (
          lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir)
        )) (name: dir + "/${name}");

      skillsFor = agent: lib.removeAttrs cfg.skills (cfg.excludedSkills.${agent} or [ ]);
    in
    {
      options.my.programs.coding-agents = {
        skillDirs = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = ''
            Directories in which every subdirectory is one skill.

            Read during evaluation, so these must be source paths. A skill that
            lives in a package belongs in {option}`skills`, where the store path
            stays a string and never forces a build.
          '';
        };

        skills = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = { };
          description = "Skills installed for every enabled coding agent, by name.";
        };

        excludedSkills = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          default = { };
          example = {
            claude-code = [ "gh" ];
          };
          description = "Skills to withhold from a given agent, keyed by agent name.";
        };
      };

      config = {
        my.programs.coding-agents = {
          skillDirs = [ ./skills ];
          skills = lib.mergeAttrsList (map skillsIn cfg.skillDirs);
        };

        programs = lib.genAttrs [ "antigravity-cli" "claude-code" "codex" "opencode" ] (agent: {
          skills = lib.mkIf config.programs.${agent}.enable (skillsFor agent);
        });

        # pi-coding-agent has no skills option upstream, so the directories are
        # placed by hand, under the configDir its own module picks.
        xdg.configFile = lib.mkIf config.programs.pi-coding-agent.enable (
          lib.mapAttrs' (name: path: lib.nameValuePair "pi/agent/skills/${name}" { source = path; }) (
            skillsFor "pi-coding-agent"
          )
        );
      };
    };
}
