{
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
      enableMcpIntegration = true;

      package = pkgs.edge.claude-code-bin;

      settings = {
        attribution = {
          commit = "Assisted-by: Claude Code Opus 4.8";
          pr = "";
        };

        statusLine = {
          type = "command";
          command = builtins.toString (
            pkgs.writeShellScript "claude-statusline" ''
              data=$(cat)

              model=$(echo "$data" | ${lib.getExe pkgs.jq} -r '.model.display_name // "?"')
              used=$(echo "$data" | ${lib.getExe pkgs.jq} -r '.context_window.used_percentage // empty')
              exceeds=$(echo "$data" | ${lib.getExe pkgs.jq} -r '.exceeds_200k_tokens // false')
              version=$(echo "$data" | ${lib.getExe pkgs.jq} -r '.version // "?"')
              branch=$(cd "$(echo "$data" | ${lib.getExe pkgs.jq} -r '.cwd // "."')" 2>/dev/null && ${lib.getExe pkgs.git} rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

              if [ -n "$used" ]; then
                used_fmt=$(printf "%.0f%%" "$used")
                if [ "$exceeds" = "true" ]; then
                  used_fmt="\033[31m''${used_fmt}\033[0m"
                fi
              else
                used_fmt="--"
              fi

              branch_fmt=""
              if [ -n "$branch" ]; then
                branch_fmt=" $branch"
              fi

              echo -e "''${model} | ctx:''${used_fmt} | v''${version}''${branch_fmt}"
            ''
          );
        };

        permissions = {
          allow = [
            "Bash(ast-grep *)"
            "Bash(cargo build *)"
            "Bash(cargo check *)"
            "Bash(cargo clippy *)"
            "Bash(cargo fmt *)"
            "Bash(cargo test *)"
            "Bash(cat *)"
            "Bash(deno check *)"
            "Bash(docker compose logs *)"
            "Bash(find *)"
            "Bash(gh api repos/attmcojp/*/comments *)"
            "Bash(gh api repos/attmcojp/*/reviews *)"
            "Bash(gh pr diff *)"
            "Bash(gh pr list *)"
            "Bash(gh pr view *)"
            "Bash(gh run list *)"
            "Bash(gh run view *)"
            "Bash(ghq list *)"
            "Bash(git * log *)"
            "Bash(git * show *)"
            "Bash(grep *)"
            "Bash(just check)"
            "Bash(ls *)"
            "Bash(mkdir *)"
            "Bash(nix build *)"
            "Bash(nix flake check*)"
            "Bash(nix log *)"
            "Bash(nix-build *)"
            "Bash(pnpm run check *)"
            "Bash(pnpm run lint *)"
            "Bash(pnpm run test *)"
            "Bash(rg *)"
            "Bash(tree *)"
            "WebFetch(domain:api.github.com)"
            "WebFetch(domain:docs.anthropic.com)"
            "WebFetch(domain:docs.github.com)"
            "WebFetch(domain:docs.renovatebot.com)"
            "WebFetch(domain:elpa.nongnu.org)"
            "WebFetch(domain:mantine.dev)"
            "WebFetch(domain:neomutt.org)"
            "WebFetch(domain:notmuchmail.org)"
            "WebFetch(domain:tailscale.com)"
            "mcp__context7__get-library-docs"
            "mcp__context7__resolve-library-id"
            "mcp__nixos__*"
            "mcp__playwright__*"
          ];
          defaultMode = "auto";
        };

        env = {
          CLAUDE_CODE_ENABLE_TELEMETRY = "1";
          OTEL_METRICS_EXPORTER = "prometheus";
          CLAUDE_CODE_AUTO_COMPACT_WINDOW = "450000";
        };
      };

      context = ../common/AGENTS.md;

      agentsDir = ./agents;

      # Exclude the shared gh skill here: Claude Code already ships built-in
      # gh tooling and commands, so the skill only duplicates them. Other
      # agents keep the full shared set, hence the per-agent filter rather than
      # dropping gh from ../common/skills.
      skills =
        let
          skillsDir = ../common/skills;
          names = builtins.attrNames (
            lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
          );
        in
        lib.genAttrs (lib.subtractLists [ "gh" ] names) (name: skillsDir + "/${name}");

      lspServers = {
        nix = {
          command = "${lib.getExe pkgs.nixd}";
          extensionToLanguage = {
            ".nix" = "nix";
          };
        };
        yaml = {
          command = "${lib.getExe pkgs.yaml-language-server}";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".yaml" = "yaml";
            ".yml" = "yaml";
          };
        };
        just = {
          command = "${lib.getExe pkgs.just-lsp}";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".justfile" = "just";
          };
        };
        terraform = {
          command = "${lib.getExe pkgs.terraform-ls}";
          args = [ "serve" ];
          extensionToLanguage = {
            ".tf" = "terraform";
            ".tfvars" = "terraform";
          };
        };
        rust = {
          command = "${lib.getExe pkgs.rust-analyzer}";
          extensionToLanguage = {
            ".rs" = "rust";
          };
        };
        typescript = {
          command = "${lib.getExe pkgs.typescript-language-server}";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".ts" = "typescript";
            ".tsx" = "typescriptreact";
            ".js" = "javascript";
            ".jsx" = "javascriptreact";
          };
        };
      };
    };

    programs.git.ignores = [
      "**/.claude/settings.local.json"
    ];

    sops.secrets.ntfy-topic = {
      sopsFile = ./../../../../homes/shared/secrets.yaml;
    };
  };
}
