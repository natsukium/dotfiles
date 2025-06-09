{
  my.programs.claude-code = {
    enable = true;
    settings = {
      includeCoAuthoredBy = false;
      permissions = {
        allow = [ ];
      };
    };
  };

  programs.git.ignores = [
    "**/.claude/settings.local.json"
  ];
}
