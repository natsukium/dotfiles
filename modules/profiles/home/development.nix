{
  imports = [
    ../../home/coding-agents/claude-code
    ../../home/coding-agents/common/mcp-servers.nix
    ../../home/coding-agents/gemini-cli
    ../../home/coding-agents/opencode
    ../../home/development/ghq
    ../../home/development/git
  ];

  my.programs.mcp.enable = true;
  my.programs.claude-code.enable = true;
  my.programs.gemini-cli.enable = true;
  my.programs.ghq.enable = true;
  my.programs.opencode.enable = true;
}
