{ lib, ... }:
import ../../lib/mkProfile.nix { inherit lib; } {
  name = "development";

  home = {
    my.programs.mcp.enable = lib.mkDefault true;
    my.programs.claude-code.enable = lib.mkDefault true;
    my.programs.antigravity-cli.enable = lib.mkDefault true;
    my.programs.codex.enable = lib.mkDefault true;
    my.programs.ghq.enable = lib.mkDefault true;
    my.programs.git.enable = lib.mkDefault true;
    my.programs.opencode.enable = lib.mkDefault true;
    my.programs.pi-coding-agent.enable = lib.mkDefault true;
    my.programs.playwright-cli.enable = lib.mkDefault true;
  };
}
