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
  };

  programs.git.ignores = [
    "**/.claude/settings.local.json"
  ];
}
