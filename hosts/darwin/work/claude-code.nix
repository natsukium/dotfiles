{ config, ... }:
{
  # The org-level AGENTS.md carries attmcojp's internal working rules, so it
  # cannot live in this public dotfiles repo as plaintext. Keep it as a sops
  # binary secret and let activation drop the decrypted copy at the ghq org
  # directory that governs every attmcojp checkout.
  sops.secrets."attmcojp-agents-md" = {
    format = "binary";
    sopsFile = ./attmcojp-agents.md;
    path = "${config.home.homeDirectory}/src/work/github.com/attmcojp/AGENTS.md";

  };

  my.programs.coding-agents.skills.attmcojp-agents-md = ./skills/attmcojp-agents-md;

  programs.claude-code.settings.permissions.allow = map (target: "Bash(make ${target})") [
    "attmcojp-agents-md-open"
    "attmcojp-agents-md-seal"
  ];
}
