{
  my.programs.claude-code = {
    enable = true;
    enableTelemetry = true;
    otelMetricsExporter = "prometheus";
    settings = {
      includeCoAuthoredBy = false;
      permissions = {
        allow = [ ];
      };
    };
    userMemory = ''
      # Code Documentation Guidelines
      - Comments should explain WHY NOT an alternative approach was chosen, rather than WHAT the code does
      - Test code should clearly describe WHAT is being tested
      - Commit messages must include WHY the change was made

      # Language Requirements
      - All documentation, comments, and commit messages must be written in English
    '';
  };

  programs.git.ignores = [
    "**/.claude/settings.local.json"
  ];
}
