# Browser automation for coding agents over a CLI instead of the Playwright MCP
# server. The MCP server holds a browser session in the agent's tool namespace and
# every snapshot lands in context; the CLI keeps the session in a background
# process and returns only what a command prints.
{ ... }:
{
  flake.modules.homeManager.playwright-cli =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.playwright-cli;
    in
    {
      options.my.programs.playwright-cli = {
        enable = lib.mkEnableOption "Playwright CLI for coding agents";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.playwright-cli ];

        # The upstream package carries its own SKILL.md, so track it rather than
        # copying a snapshot that would drift on every version bump.
        my.programs.coding-agents.skills.playwright-cli =
          "${pkgs.playwright-cli}/lib/node_modules/@playwright/cli/skills/playwright-cli";
      };
    };
}
