{ ... }:
{
  flake.modules.homeManager.coding-agent =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.coding-agents;

      hook = pkgs.writers.writePython3 "prepare-commit-msg" {
        flakeIgnore = [ "E501" ];
      } ./prepare-commit-msg.py;

      # Git copies templates verbatim, so a symlink would dangle once the store
      # path is collected; the hook must be a real file.
      templateDir = pkgs.runCommand "git-template-assisted-by" { } ''
        mkdir -p $out/hooks
        cp ${hook} $out/hooks/prepare-commit-msg
        chmod +x $out/hooks/prepare-commit-msg
      '';
    in
    {
      # nixpkgs' transparency policy requires LLM assistance on commits to be
      # disclosed as an `Assisted-by:` trailer naming the tool and the model
      # (https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md). Rather
      # than trusting each session to remember the trailer, a prepare-commit-msg
      # hook appends it mechanically. Attribution keys off the environment
      # variable each supported agent exports (PI_CODING_AGENT, CLAUDECODE);
      # agents exporting none stay unsupported.
      #
      # The hook ships through init.templatedir instead of core.hooksPath
      # because hooksPath replaces .git/hooks wholesale and would break repos
      # using husky or pre-commit. Templates only reach new clones and
      # `git init`s, though — run it once inside an existing repo to pick the
      # hook up.
      options.my.programs.coding-agents.gitTrailer.enable =
        lib.mkEnableOption "the Assisted-by commit trailer for coding agents";

      config = {
        my.programs.coding-agents.gitTrailer.enable = lib.mkDefault (
          config.programs.claude-code.enable || config.programs.pi-coding-agent.enable
        );

        programs.git.settings.init.templatedir = lib.mkIf (
          cfg.gitTrailer.enable && config.programs.git.enable
        ) "${templateDir}";
      };
    };
}
