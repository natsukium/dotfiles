{ pkgs, ... }:
{
  imports = [
    ../../home/coding-agents/claude-code
    ../../home/coding-agents/gemini-cli
    ../../home/coding-agents/opencode
  ];

  my.programs.claude-code.enable = true;
  my.programs.gemini-cli.enable = true;
  # problems with bun
  # https://github.com/oven-sh/bun/issues/24645
  my.programs.opencode.enable = pkgs.stdenv.hostPlatform.isLinux;
}
