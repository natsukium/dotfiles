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

      # Git copies the template into a repo once and never revisits it, so a
      # hook whose body lived in the copied file would freeze at the revision
      # installed on the day of the clone. The copy is a dispatcher instead: it
      # resolves init.templatedir at run time and executes the body from the
      # template the active generation points at, so a `switch` updates every
      # repo that already carries the hook. The fallback covers the window
      # before the first switch, when init.templatedir still names a template
      # that holds a self-contained hook and no body file.
      dispatcher = pkgs.writeShellScript "prepare-commit-msg" ''
        template=$(git config --get init.templatedir) || exit 0
        if [ -x "$template/hooks/prepare-commit-msg.py" ]; then
          exec "$template/hooks/prepare-commit-msg.py" "$@"
        fi
        [ -x "$template/hooks/prepare-commit-msg" ] \
          && exec "$template/hooks/prepare-commit-msg" "$@"
        exit 0
      '';

      templateDir = pkgs.runCommand "git-template-assisted-by" { } ''
        mkdir -p $out/hooks
        cp ${dispatcher} $out/hooks/prepare-commit-msg
        cp ${hook} $out/hooks/prepare-commit-msg.py
        chmod +x $out/hooks/prepare-commit-msg $out/hooks/prepare-commit-msg.py
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
      # `git init`s, so an existing repo still needs one manual copy of the
      # current template; because that copy is a dispatcher, later revisions
      # follow with a `switch` rather than another per-repo copy.
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
