{
  inputs,
  config,
  pkgs,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    settings = {
      includeCoAuthoredBy = false;
      permissions = {
        allow = [
          "Bash(ast-grep:*)"
          "Bash(cargo build:*)"
          "Bash(cargo check:*)"
          "Bash(cargo clippy:*)"
          "Bash(cargo test:*)"
          "Bash(deno check:*)"
          "Bash(find:*)"
          "Bash(grep:*)"
          "Bash(pnpm run check:*)"
          "Bash(pnpm run lint:*)"
          "Bash(pnpm run test:*)"
          "Bash(rg:*)"
        ];
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

    commands = {
      commit-staged = ''
        ---
        allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git commit:*)
        argument-hint: intention
        description: Review staged changes and create commit with appropriate message
        model: claude-sonnet-4-20250514
        ---

        ## Context

        - Current git status: !`git status --short`
        - Staged changes: !`git diff --cached --stat`
        - Detailed staged diff: !`git diff --cached`
        - Recent commit history: !`git log --oneline -10`

        ## Your task

        Based on the staged changes above, create a commit with an appropriate message that:
        1. Follows the repository's existing commit message style (refer to recent commits)
        2. Explains WHY the change was made, not just what changed
        3. Is concise but informative
        4. If no staged changes exist, inform the user and do not create an empty commit

        ## Additinoal Instructions

        $ARGUMENTS
      '';
    };

    mcpServers =
      (inputs.mcp-servers.lib.evalModule pkgs {
        programs = {
          context7.enable = true;
          playwright.enable = true;
          serena = {
            enable = true;
            args = [
              "--context=ide-assistant"
              "--enable-web-dashboard=false"
            ];
          };
          time = {
            enable = true;
            args = [ "--local-timezone=Asia/Tokyo" ];
          };
        };
      }).config.settings.servers;
  };

  home.file.".claude/CLAUDE.md".text = ''
    # Code Documentation Guidelines
    - Comments should explain WHY NOT an alternative approach was chosen, rather than WHAT the code does
    - Test code should clearly describe WHAT is being tested
    - Commit messages must include WHY the change was made

    # Language Requirements
    - All documentation, comments, and commit messages must be written in English

    # Available Tools
    - ast-grep: Use for AST-based code searching and structural pattern matching
    - ghq: Use for cloning GitHub repositories to $(ghq root)/$org/$repo and prioritize local code search over web search
  '';

  programs.git.ignores = [
    "**/.claude/settings.local.json"
  ];

  sops.secrets.ntfy-topic = {
    sopsFile = ./../../homes/shared/secrets.yaml;
  };
}
