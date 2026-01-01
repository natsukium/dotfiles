{ pkgs }:
{
  # Generate AGENTS.md with tool instructions from skills
  # Used by gemini-cli and opencode (Claude Code uses skills directly)
  rulesWithTools =
    pkgs.runCommand "AGENTS.md"
      {
        nativeBuildInputs = [ pkgs.python3 ];
      }
      ''
        python3 ${./build-rules.py} ${./AGENTS.md} ${./skills} > $out
      '';
}
