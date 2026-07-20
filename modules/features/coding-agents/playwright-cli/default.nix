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

        # The skills option probes the path with `pathIsDirectory`, so pointing
        # it at the package (or its `src` derivation) is an import-from-derivation
        # that `nix flake check --no-build` refuses. fetchTarball runs in the
        # evaluator instead, and reusing `src`'s coordinates keeps one version pin
        # that follows nur-packages; a fetchFromGitHub `outputHash` is the
        # unpacked-tree NAR hash fetchTarball verifies.
        my.programs.coding-agents.skills.playwright-cli =
          let
            inherit (pkgs.playwright-cli.src) url outputHash;
          in
          "${
            fetchTarball {
              inherit url;
              sha256 = outputHash;
            }
          }/skills/playwright-cli";
      };
    };
}
