{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.programs.opencode;
  commonLib = import ../common/lib.nix { inherit pkgs; };

  # Transform MCP server config
  # - add type="local"
  # - merge command+args into array
  # - rename env->environment
  transformMcpServerConfig =
    _: v:
    lib.removeAttrs
      (
        v
        // {
          type = "local";
          command = [ v.command ] ++ (v.args or [ ]);
          environment = v.env or { };
        }
      )
      [
        "args"
        "env"
      ];
in
{
  options.my.programs.opencode = {
    enable = lib.mkEnableOption "opencode LLM agent";
  };

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      rules = builtins.readFile commonLib.rulesWithTools;

      settings = {
        instructions = [ "CLAUDE.md" ];

        autoupdate = false;

        theme = "nord";

        mcp = lib.mapAttrs transformMcpServerConfig (
          import ../common/mcp-servers.nix { inherit inputs pkgs; }
        );
      };
    };

    home.sessionVariables.OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
  };
}
