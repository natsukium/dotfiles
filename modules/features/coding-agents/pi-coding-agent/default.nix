{ inputs, ... }:
{
  flake.modules.homeManager.pi-coding-agent =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.pi-coding-agent;

      # Merge source for the mutable settings.json installed by the
      # activation script below.
      settingsFile =
        (pkgs.formats.json { }).generate "pi-coding-agent-settings.json"
          config.programs.pi-coding-agent.settings;
    in
    {
      options.my.programs.pi-coding-agent = {
        enable = lib.mkEnableOption "pi coding agent CLI";
      };

      config = lib.mkIf cfg.enable {
        # jq runs in the activation script and is absent from its default PATH.
        home.extraActivationPath = [ pkgs.jq ];

        programs.pi-coding-agent = {
          enable = true;
          configDir = "${config.xdg.configHome}/pi/agent";
          context = ../common/AGENTS.md;
        };

        # Reuse repo-local Claude skills in pi instead of maintaining parallel
        # .agents/skills copies.
        home.file."${config.programs.pi-coding-agent.configDir}/extensions/claude-project-skills.ts".source =
          ./extensions/claude-project-skills.ts;

        # pi's /settings UI writes settings.json in place, which fails on the
        # read-only store symlink the upstream module installs. pi has no
        # include mechanism for settings files, so each switch deep-merges the
        # Nix-declared keys over a mutable live copy instead; UI-only values
        # survive.
        home.file."${config.programs.pi-coding-agent.configDir}/settings.json".enable = false;

        home.activation.pi-coding-agent-settings =
          inputs.home-manager.lib.hm.dag.entryAfter [ "linkGeneration" ]
            ''
              dir="${config.programs.pi-coding-agent.configDir}"
              target="$dir/settings.json"
              mkdir -p "$dir"
              if [[ -e "$target" ]]; then
                jq -s '.[0] * .[1]' "$target" ${settingsFile} > "$target.tmp"
                mv "$target.tmp" "$target"
              else
                # cat, not cp: cp would inherit the store file's read-only mode.
                cat ${settingsFile} > "$target"
              fi
            '';
      };
    };
}
