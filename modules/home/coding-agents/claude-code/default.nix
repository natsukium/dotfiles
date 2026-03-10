{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.claude-code;

  # Standard Claude Code plugin directory with .lsp.json containing all language
  # servers. replaceVars substitutes @pkg@ placeholders with /nix/store paths.
  lspPlugin = pkgs.runCommandLocal "claude-lsp" { } ''
    cp -r ${./plugins/lsp} $out
    chmod -R u+w $out
    cp ${
      pkgs.replaceVars ./plugins/lsp/.lsp.json {
        nixd = "${pkgs.nixd}/bin/nixd";
        yaml_language_server = "${pkgs.yaml-language-server}/bin/yaml-language-server";
        just_lsp = "${pkgs.just-lsp}/bin/just-lsp";
        terraform_ls = "${pkgs.terraform-ls}/bin/terraform-ls";
        rust_analyzer = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        typescript_language_server = "${pkgs.typescript-language-server}/bin/typescript-language-server";
      }
    } $out/.lsp.json
  '';

  # Re-wrap the upstream binary to inject --plugin-dir flags for each LSP plugin.
  # Cannot use wrapProgram twice because makeBinaryWrapper would overwrite
  # .claude-wrapped; instead, manually rename and call makeBinaryWrapper.
  claudeWithLsp = pkgs.edge.claude-code-bin.overrideAttrs (prev: {
    postInstall = (prev.postInstall or "") + ''
      mv $out/bin/claude $out/bin/.claude-lsp-wrapped
      makeBinaryWrapper $out/bin/.claude-lsp-wrapped $out/bin/claude \
        --add-flags '--plugin-dir ${lspPlugin}'
    '';
  });
in
{
  options.my.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code LLM agent";
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;

      package = claudeWithLsp;

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
            "Bash(nix build *)"
            "Bash(nix flake check*)"
            "Bash(nix-build *)"
            "Bash(pnpm run check:*)"
            "Bash(pnpm run lint:*)"
            "Bash(pnpm run test:*)"
            "Bash(rg:*)"
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
            "mcp__nixos*"
            "mcp__playwright__browser_click"
            "mcp__playwright__browser_console_messages"
            "mcp__playwright__browser_navigate"
            "mcp__playwright__browser_network_requests"
            "mcp__playwright__browser_snapshot"
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

      skillsDir = ../common/skills;

    };

    programs.git.ignores = [
      "**/.claude/settings.local.json"
    ];

    sops.secrets.ntfy-topic = {
      sopsFile = ./../../../../homes/shared/secrets.yaml;
    };
  };
}
