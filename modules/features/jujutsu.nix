# This file is auto-generated from configuration.org.
# Do not edit directly.

{ ... }:
{
  flake.modules.homeManager.jujutsu =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.jujutsu;
      gitCfg = config.programs.git;
    in
    {
      options.my.programs.jujutsu.enable = lib.mkEnableOption "jujutsu";

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = config.my.programs.git.enable;
            message = "my.programs.jujutsu reuses git's identity, signing key and editor; enable my.programs.git too.";
          }
        ];

        programs.jujutsu = {
          enable = true;

          settings = {
            user = {
              inherit (gitCfg.settings.user) name email;
            };

            signing = {
              backend =
                {
                  openpgp = "gpg";
                  ssh = "ssh";
                  x509 = "gpgsm";
                }
                .${gitCfg.signing.format};
              behavior = if gitCfg.signing.signByDefault then "own" else "keep";
              key = gitCfg.signing.key;
            };

            ui = {
              default-command = [ "log" ];
              editor = gitCfg.settings.core.editor;
              diff-formatter = [
                (lib.getExe pkgs.difftastic)
                "--color=always"
                "$left"
                "$right"
              ];
            };

            snapshot.max-new-file-size = "1MiB";
          };
        };
      };
    };
}
