{ config, ... }:
{
  # The org-level CLAUDE.md carries attmcojp's internal working rules, so it
  # cannot live in this public dotfiles repo as plaintext. Keep it as a sops
  # binary secret and let activation drop the decrypted copy at the ghq org
  # directory that governs every attmcojp checkout.
  sops.secrets."attmcojp-claude-md" = {
    format = "binary";
    sopsFile = ./attmcojp-claude.md;
    path = "${config.home.homeDirectory}/src/work/github.com/attmcojp/CLAUDE.md";

  };

  my.programs.coding-agents.skills.attmcojp-claude-md = ./skills/attmcojp-claude-md;

  programs.claude-code.settings.permissions.allow = map (target: "Bash(make ${target})") [
    "attmcojp-claude-md-open"
    "attmcojp-claude-md-seal"
  ];
}
