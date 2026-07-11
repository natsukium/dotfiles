{ ... }:
{
  flake.modules.homeManager.ghq =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.ghq;

      urlSettingsModule = lib.types.submodule {
        options = {
          root = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Root directory for repositories from this URL.";
          };
          vcs = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.enum [
                "git"
                "subversion"
                "git-svn"
                "mercurial"
                "darcs"
                "fossil"
                "bazaar"
              ]
            );
            default = null;
            description = "VCS type for repositories from this URL.";
          };
        };
      };

      reservedNames = [
        "enable"
        "package"
        "root"
        "environmentVariable"
      ];

      rootValue = if cfg.root == [ ] || cfg.root == "" then null else cfg.root;

      urlSettings = lib.filterAttrs (name: _: !(builtins.elem name reservedNames)) cfg;

      urlGitSettings = lib.mapAttrs' (
        url: settings: lib.nameValuePair "ghq \"${url}\"" (lib.filterAttrs (_: v: v != null) settings)
      ) (lib.filterAttrs (_: v: v.root != null || v.vcs != null) urlSettings);
    in
    {
      options.my.programs.ghq = lib.mkOption {
        type = lib.types.submodule {
          freeformType = lib.types.attrsOf urlSettingsModule;

          options = {
            enable = lib.mkEnableOption "ghq - Git repository management";

            package = lib.mkPackageOption pkgs "ghq" { };

            root = lib.mkOption {
              type = with lib.types; either str (listOf str);
              default = [ ];
              example = [
                "/home/user/ghq/example"
              ];
              description = "Root directory or list of directories. Last one becomes primary.";
            };
          };
        };
        default = { };
      };

      config = lib.mkMerge [
        # Personal default: every host's primary user keeps ghq clones under
        # ~/src/private, so the root is set here rather than per-host. mkDefault
        # rather than a plain value so a home that wants a different root can just
        # assign it, instead of hitting an unresolvable option conflict against
        # this always-present definition and needing mkForce to escape it.
        { my.programs.ghq.root = lib.mkDefault "${config.home.homeDirectory}/src/private"; }

        (lib.mkIf cfg.enable {
          home.packages = [ cfg.package ];

          programs.git.settings = lib.mkMerge [
            (lib.mkIf (rootValue != null) { ghq.root = rootValue; })
            urlGitSettings
          ];
        })
      ];
    };
}
