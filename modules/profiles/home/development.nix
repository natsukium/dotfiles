{
  imports = [
    ../../home/coding-agents/antigravity-cli
    ../../home/coding-agents/claude-code
    ../../home/coding-agents/codex
    ../../home/coding-agents/common/mcp-servers.nix
    ../../home/coding-agents/opencode
    ../../home/coding-agents/pi-coding-agent
    ../../home/development/ghq
    ../../home/development/git
  ];

  my.programs.mcp.enable = true;
  my.programs.claude-code.enable = true;
  my.programs.antigravity-cli.enable = true;
  my.programs.codex.enable = true;
  my.programs.ghq.enable = true;
  my.programs.opencode.enable = true;
  my.programs.pi-coding-agent.enable = true;
}
