{ ... }:
{
  flake.modules.homeManager.claude-code =
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
        # Claude Code ships built-in gh tooling and commands, so the shared gh
        # skill only duplicates them.
        my.programs.coding-agents.excludedSkills.claude-code = [ "gh" ];

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
              # deny wins over allow and over the auto-mode classifier, so it is the
              # only rule intent cannot talk past. Guard secret material here rather
              # than trusting the allow-list to stay tight.
              deny = [
                # ~/.ssh holds plaintext private keys and the agent never needs any
                # of it, so block the whole tree (config included) instead of
                # guessing key filenames.
                "Read(**/.ssh/**)"
                "Bash(cat *.ssh/*)"
                # .env secrets sit in plaintext, so the read itself is the leak.
                "Read(**/.env)"
                "Read(**/.env.*)"
                "Bash(cat *.env*)"
                # age/sops files are ciphertext at rest, so reading them leaks
                # nothing; the exposure is decryption to stdout. Block only the
                # commands that dump plaintext to stdout. sops exec-env/exec-file are
                # deliberately excluded: they inject secrets into a subprocess env or
                # temp file to *avoid* exposing them, and are the legitimate way to
                # use secrets. String-matching is evadable, so this is a speed-bump.
                "Bash(sops -d *)"
                "Bash(sops --decrypt *)"
                "Bash(sops decrypt *)"
                "Bash(age -d *)"
                "Bash(age --decrypt *)"
                "Bash(rage -d *)"
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
      };
    };
}
