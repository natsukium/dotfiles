{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.claude-code;
in
{
  options.my.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code LLM agent";
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;

      package = pkgs.edge.claude-code;

      settings = {
        includeCoAuthoredBy = false;

        permissions = {
          allow = [
            "Bash(ast-grep:*)"
            "Bash(cargo build:*)"
            "Bash(cargo check:*)"
            "Bash(cargo clippy:*)"
            "Bash(cargo fmt:*)"
            "Bash(cargo test:*)"
            "Bash(deno check:*)"
            "Bash(docker compose logs:*)"
            "Bash(find:*)"
            "Bash(gh pr diff:*)"
            "Bash(gh pr list:*)"
            "Bash(gh pr view:*)"
            "Bash(gh run list:*)"
            "Bash(gh run view:*)"
            "Bash(ghq list:*)"
            "Bash(git log:*)"
            "Bash(grep:*)"
            "Bash(just check)"
            "Bash(pnpm run check:*)"
            "Bash(pnpm run lint:*)"
            "Bash(pnpm run test:*)"
            "Bash(rg:*)"
            "mcp__playwright__browser_click"
            "mcp__playwright__browser_console_messages"
            "mcp__playwright__browser_navigate"
            "mcp__playwright__browser_network_requests"
            "mcp__playwright__browser_snapshot"
            "mcp__serena__activate_project"
            "mcp__serena__check_onboarding_performed"
            "mcp__serena__find_file"
            "mcp__serena__find_symbol"
            "mcp__serena__get_symbols_overview"
            "mcp__serena__list_dir"
            "mcp__serena__onboarding"
            "mcp__serena__read_memory"
            "mcp__serena__search_for_pattern"
            "mcp__serena__think_about_collected_information"
            "mcp__serena__write_memory"
            "mcp__time__get_current_time"
          ];
          defaultMode = "plan";
        };

        hooks = {
          Notification = [
            {
              matcher = "";
              hooks = [
                {
                  type = "command";
                  command = "jq -r .message | curl -H 'Title: Claude Code' -d @- ntfy.sh/$(cat ${config.sops.secrets.ntfy-topic.path})";
                }
              ];
            }
          ];
        };

        env = {
          CLAUDE_CODE_ENABLE_TELEMETRY = "1";
          OTEL_METRICS_EXPORTER = "prometheus";
        };
      };

      memory.source = ../common/AGENTS.md;

      agentsDir = ./agents;

      commandsDir = ./commands;

      mcpServers = import ../common/mcp-servers.nix { inherit inputs pkgs; };
    };

    programs.git.ignores = [
      "**/.claude/settings.local.json"
      ".serena/"
    ];

    sops.secrets.ntfy-topic = {
      sopsFile = ./../../../../homes/shared/secrets.yaml;
    };
  };
}
